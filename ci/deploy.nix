{
  host,
  node,
  pkgs,
}:
let
  inherit (pkgs.lib)
    escapeShellArg
    toJSON
    ;

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

  knownHosts = pkgs.writeText "deploy-known-hosts" ''
    azaleoid.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICG6HIBl+a6c5Iw9kpB+vscaAhs4fz0OffcRlB/10l7m
    bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLFDSdSXx3Tmko6gRTpqih3Ruq6zko+y/JYRUG95Dl9
    erythron.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ1JtPoFr8YrVkNrJs2tO1nHcVYoBqwZVwFLHON5ayN
    magnolia.tail.bingshan.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlZHUHM5kNwUFOA54cF6LDrwiw9VUQpq1M7IhwyoyTQ
  '';
in
pkgs.writeShellScript "deploy-${host}" ''
  set -euo pipefail
  umask 077
  credentials=$(mktemp -d)
  trap 'rm -rf "$credentials"' EXIT
  jq -er '.ssh.data.privateKey' "$HERCULES_CI_SECRETS_JSON" \
    > "$credentials/id"
  ssh_options=(
    -i "$credentials/id"
    -o IdentitiesOnly=yes
    -o BatchMode=yes
    -o ConnectTimeout=30
    -o ServerAliveInterval=15
    -o ServerAliveCountMax=4
    -o StrictHostKeyChecking=yes
    -o UserKnownHostsFile=${knownHosts}
  )
  destination=${escapeShellArg "${node.sshUser}@${node.hostname}"}
  export NIX_SSHOPTS="''${ssh_options[*]}"

  case "$1" in
    inspect)
      ssh "''${ssh_options[@]}" "$destination" '
        set -eu
        readlink -f /run/current-system
        readlink -f /nix/var/nix/profiles/system
        systemctl --failed --no-legend --plain --no-pager
      '
      ;;
    activate)
      # Restarting this agent would kill its own rollback monitor.
      local_boot=$(cat /proc/sys/kernel/random/boot_id)
      remote_boot=$(ssh "''${ssh_options[@]}" "$destination" \
        cat /proc/sys/kernel/random/boot_id)
      if [ "$local_boot" = "$remote_boot" ]; then
        echo "Refusing to deploy the executing agent." >&2
        exit 1
      fi

      deploy ${deployment}#${host} --skip-checks \
        --ssh-opts "$NIX_SSHOPTS" \
        --auto-rollback true --magic-rollback true
      ;;
    *)
      echo "Unknown deployment operation" >&2
      exit 1
      ;;
  esac
''
