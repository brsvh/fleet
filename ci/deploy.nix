{
  attempt,
  host,
  inputs,
  rev,
  runId,
  self,
  system,
}:
let
  inherit (inputs.nixpkgs.lib)
    toJSON
    ;

  pkgs = inputs.nixpkgs.legacyPackages.${system};

  effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;

  node = self.deploy.nodes.${host};

  # A tiny input-free flake carries the already-built profile. The approval
  # cannot accidentally pick up a newer lock file or a newer branch revision.
  deployment = pkgs.writeTextDir "flake.nix" ''
    {
      outputs = _:
        let
          inherit (builtins)
            appendContext
            fromJSON
            mapAttrs
            ;

          node = fromJSON ${toJSON (toJSON node)};
        in
        {
          deploy = {
            nodes = {
              ${host} = node // {
                profiles = mapAttrs (
                  _: profile:
                  profile // {
                    path = appendContext profile.path {
                      "''${profile.path}" = {
                        path = true;
                      };
                    };
                  }
                ) node.profiles;
              };
            };
          };
        };
    }
  '';

  repository = "brsvh/fleet";

  verifyDeployment = pkgs.writeText "verify-deployment.mjs" ''
    // Runs inside the Hercules Effect before any SSH connection or activation.
    const [repository, sha, host, runId, attempt] = process.argv.slice(2);
    if (!/^[^/]+\/[^/]+$/.test(repository) || !/^[0-9a-f]{40}$/.test(sha) ||
        !/^[a-z0-9-]+$/.test(host) || !/^\d+$/.test(runId) || !/^\d+$/.test(attempt)) {
      throw new Error('Invalid deployment request');
    }
    const api = async path => {
      const response = await fetch(`https://api.github.com/repos/''${repository}/''${path}`, {
        headers: {accept: 'application/vnd.github+json', 'user-agent': 'hercules-deploy'},
        signal: AbortSignal.timeout(30000),
      });
      if (!response.ok) throw new Error(`GitHub approval lookup failed (''${response.status})`);
      return response.json();
    };
    const environment = `deploy-''${host}`;
    const [main, run, reviews, config, jobs] = await Promise.all([
      api('git/ref/heads/main'),
      api(`actions/runs/''${runId}/attempts/''${attempt}`),
      api(`actions/runs/''${runId}/approvals`),
      api(`environments/''${environment}`),
      api(`actions/runs/''${runId}/attempts/''${attempt}/jobs?per_page=100`),
    ]);
    if (main.object.sha !== sha || run.head_sha !== sha || run.head_branch !== 'main' ||
        run.event !== 'repository_dispatch' || run.path !== '.github/workflows/ci.yml' ||
        run.run_attempt !== Number(attempt) || run.repository.full_name !== repository ||
        !['in_progress', 'waiting', 'completed'].includes(run.status) || run.conclusion === 'cancelled') {
      throw new Error('The approval workflow does not match the current main deployment');
    }
    if (!config.protection_rules?.some(rule => rule.type === 'required_reviewers' && rule.reviewers?.length) ||
        !reviews.some(review => review.state === 'approved' &&
          review.environments.some(item => item.name === environment))) {
      throw new Error(`Required approval for ''${environment} is missing`);
    }
    if (!jobs.jobs.some(job => job.name === `Approve / ''${host}` &&
        (job.status === 'in_progress' || (job.status === 'completed' && job.conclusion === 'success')))) {
      throw new Error('The deployment approval job is not active or successful');
    }
    console.log(`Verified approval: ''${repository}@''${sha}, ''${environment}, run ''${runId}/''${attempt}`);
  '';

  knownHosts = pkgs.writeText "deploy-known-hosts" ''
    azaleoid.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICG6HIBl+a6c5Iw9kpB+vscaAhs4fz0OffcRlB/10l7m
    bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLFDSdSXx3Tmko6gRTpqih3Ruq6zko+y/JYRUG95Dl9
    erythron.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ1JtPoFr8YrVkNrJs2tO1nHcVYoBqwZVwFLHON5ayN
    magnolia.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlZHUHM5kNwUFOA54cF6LDrwiw9VUQpq1M7IhwyoyTQ
  '';
in
assert host != "magnolia";
effects.mkEffect {
  NIX_CONFIG = ''
    extra-experimental-features = nix-command flakes
  '';

  dontUnpack = true;

  effectScript = ''
    (
      set -euo pipefail
      umask 077
      node ${verifyDeployment} \
        ${repository} ${rev} ${host} ${runId} ${attempt}

      credentials=$(mktemp -d)
      trap 'rm -rf "$credentials"' EXIT
      readSecretString ssh .privateKey > "$credentials/id"
      ssh_options=(
        -i "$credentials/id"
        -o IdentitiesOnly=yes
        -o BatchMode=yes
        -o StrictHostKeyChecking=yes
        -o UserKnownHostsFile=${knownHosts}
      )
      export NIX_SSHOPTS="''${ssh_options[*]}"

      # Restarting the agent would kill its own Effect and rollback monitor.
      local_boot=$(cat /proc/sys/kernel/random/boot_id)
      remote_boot=$(ssh "''${ssh_options[@]}" ${node.sshUser}@${node.hostname} \
        cat /proc/sys/kernel/random/boot_id)
      if [ "$local_boot" = "$remote_boot" ]; then
        echo "Refusing to deploy the executing agent; maintain this host manually." >&2
        exit 1
      fi

      deploy ${deployment}#${host} --skip-checks \
        --ssh-opts "$NIX_SSHOPTS" \
        --auto-rollback true --magic-rollback true
    )
  '';

  inputs = with pkgs; [
    coreutils
    inputs.deploy.packages.${system}.default
    nix
    nodejs
    openssh
  ];

  name = "deploy-${host}";

  requiredSystemFeatures = [
    "deploy"
  ];

  secretsMap = {
    ssh = "deploy-ssh";
  };
}
