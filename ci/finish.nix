{
  branch,
  inputs,
  rev,
  system,
  tag,
  target,
}:
let
  inherit (inputs.nixpkgs.lib)
    toJSON
    ;

  pkgs = inputs.nixpkgs.legacyPackages.${system};

  effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;

  request =
    pkgs.writeText "finish-request.json"
      (toJSON {
        inherit
          branch
          rev
          tag
          ;

        host =
          if target.kind == "host" && target.deploy then
            target.name
          else
            null;
      });

  finish = pkgs.writeText "finish.mjs" ''
    import fs from 'node:fs';

    const {branch, rev, tag, host} = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const secrets = JSON.parse(fs.readFileSync(process.env.HERCULES_CI_SECRETS_JSON, 'utf8'));
    const token = secrets.git?.data.token;
    if (!token) throw new Error('Missing GitHub credential');
    const api = async (path, method = 'GET', body) => {
      const response = await fetch(`https://api.github.com/repos/brsvh/fleet/''${path}`, {
        method,
        headers: {
          accept: 'application/vnd.github+json', authorization: `Bearer ''${token}`,
          'content-type': 'application/json', 'user-agent': 'fleet-ci',
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(30000),
      });
      if (method === 'DELETE' && response.status === 422) return null;
      if (!response.ok) throw new Error(`GitHub request failed (''${response.status})`);
      return response.status === 204 ? null : response.json();
    };
    // Each finishing Effect receives a fresh token after its builds, even when
    // those builds take longer than a GitHub installation token's lifetime.
    await api(`git/refs/tags/''${tag}`, 'DELETE');
    if (branch === 'main' && host) {
      if ((await api('git/ref/heads/main')).object.sha !== rev) {
        console.log('Skipping approval for a superseded main revision');
      } else {
        const query = new URLSearchParams({ref: 'refs/heads/main', rev, handler: 'OnPush', name: 'plan', limit: '20'});
        const response = await fetch(`https://hercules-ci.com/api/v1/site/github/account/brsvh/project/fleet/jobs?''${query}`, {
          signal: AbortSignal.timeout(30000),
        });
        if (!response.ok) throw new Error('Could not verify the planning result');
        const {items} = await response.json();
        const plan = items.find(job => job.jobName === 'plan' && job.source.revision === rev &&
          job.source.ref === 'refs/heads/main');
        if (!plan || plan.jobStatus !== 'Success' || plan.isCancelled) {
          throw new Error('The planning job has not succeeded');
        }
        await api('dispatches', 'POST', {
          event_type: 'fleet-deploy', client_payload: {rev, hosts: [host]},
        });
        console.log(`Requested deployment approval for ''${host} at ''${rev}`);
      }
    }
  '';
in
effects.mkEffect {
  dontUnpack = true;

  effectScript = ''
    node ${finish} ${request}
  '';

  inputs = with pkgs; [
    nodejs
  ];

  name = "finish-fleet-check";

  secretsMap = {
    git = {
      type = "GitToken";
    };
  };
}
