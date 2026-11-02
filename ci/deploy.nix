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
  export LC_ALL=C

  ssh_read() {
    local attempt status

    for attempt in 1 2 3 4 5; do
      if timeout 90 ssh "''${ssh_options[@]}" "$destination" "$@" \
        > "$credentials/output" 2> "$credentials/error"; then
        cat "$credentials/output"
        return 0
      else
        status=$?
      fi

      cat "$credentials/error" >&2
      echo "SSH check for ${host} failed ($attempt/5)." >&2

      if grep -Eqi \
        'permission denied|authentication failed|host key|bad configuration|invalid' \
        "$credentials/error"; then
        return "$status"
      fi

      if [ "$status" -ne 124 ] && {
        [ "$status" -ne 255 ] || ! grep -Eqi \
          'timed out|connection (reset|refused|closed)|broken pipe|no route to host|network is unreachable|temporary failure in name resolution' \
          "$credentials/error"
      }; then
        return "$status"
      fi

      if [ "$attempt" -eq 5 ]; then
        return "$status"
      fi

      echo "Retrying SSH check in one minute." >&2
      sleep 60
    done
  }

  case "$1" in
    inspect)
      output=$(ssh_read '
        set -eu
        cat /proc/sys/kernel/random/boot_id
        readlink -f /run/current-system
        readlink -f /nix/var/nix/profiles/system
        systemctl --failed --no-legend --plain --no-pager
      ')
      IFS= read -r remote_boot <<< "$output"

      if ! [[ "$remote_boot" =~ ^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$ ]]; then
        echo "Could not determine the remote boot ID." >&2
        exit 1
      fi

      # Restarting this agent would kill its own rollback monitor.
      local_boot=$(cat /proc/sys/kernel/random/boot_id)

      if [ "$local_boot" = "$remote_boot" ]; then
        echo "Refusing to deploy the executing agent." >&2
        exit 1
      fi

      printf '%s\n' "''${output#*$'\n'}"
      ;;
    activate)
      deploy ${deployment}#${host} --skip-checks \
        --ssh-opts "$NIX_SSHOPTS" \
        --auto-rollback true --magic-rollback true
      ;;
    diagnose)
      timeout 30 ssh "''${ssh_options[@]}" "$destination" '
        readlink -f /run/current-system
        readlink -f /nix/var/nix/profiles/system
        systemctl --failed --no-legend --plain --no-pager
        systemctl list-jobs --no-pager
        journalctl -b -p err -n 80 --no-pager
      '
      ;;
    *)
      echo "Unknown deployment operation" >&2
      exit 1
      ;;
  esac
''
