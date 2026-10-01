{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArgs
    length
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.github-interaction-limits;
in
{
  options = {
    services = {
      github-interaction-limits = {
        enable = mkEnableOption "GitHub interaction restriction renewal";

        repositories = mkOption {
          description = ''
            Repositories whose interactions are restricted to collaborators,
            each in owner/name form.
          '';

          type =
            with types;
            nonEmptyListOf (
              strMatching "[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"
            );
        };

        tokenFile = mkOption {
          description = ''
            Runtime file containing a GitHub token with Administration write
            permission for every repository. Do not put the token in the store.
          '';

          type = types.str;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      services = {
        github-interaction-limits = {
          description = "Renew GitHub collaborator-only interactions";

          after = [
            "network-online.target"
            "sops-install-secrets.service"
          ];

          wants = [
            "network-online.target"
          ];

          path = with pkgs; [
            coreutils
            curl
            jq
          ];

          script = ''
            set -euo pipefail
            token=$(cat "$CREDENTIALS_DIRECTORY/token")
            case "$token" in
              ""|*[!a-zA-Z0-9_]*)
                echo "Invalid GitHub token format" >&2
                exit 1
                ;;
            esac

            failed=0
            repositories=(${escapeShellArgs cfg.repositories})
            for repository in "''${repositories[@]}"; do
              # Feed the credential through stdin so it never appears in argv.
              if ! response=$(printf 'Authorization: Bearer %s\n' "$token" |
                curl --fail-with-body --silent --show-error \
                  --connect-timeout 15 --max-time 60 \
                  --retry 3 --retry-delay 10 --retry-all-errors \
                  --request PUT \
                  --header @- \
                  --header 'Accept: application/vnd.github+json' \
                  --header 'Content-Type: application/json' \
                  --data '{"limit":"collaborators_only","expiry":"six_months"}' \
                  "https://api.github.com/repos/$repository/interaction-limits"); then
                echo "Failed to renew interactions for $repository" >&2
                failed=1
                continue
              fi
              if ! printf '%s' "$response" | jq -e '
                .limit == "collaborators_only" and
                (.expires_at | fromdateiso8601) > (now + 120 * 86400)
              ' > /dev/null; then
                echo "Invalid renewal response for $repository" >&2
                failed=1
                continue
              fi
              printf '%s' "$response" | jq -r --arg repository "$repository" '
                $repository + ": interactions restricted to collaborators until " + .expires_at
              '
            done
            unset token
            exit "$failed"
          '';

          serviceConfig = {
            DynamicUser = true;

            LoadCredential = [
              "token:${cfg.tokenFile}"
            ];

            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            Restart = "on-failure";
            RestartSec = "1h";

            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];

            TimeoutStartSec = 300 * length cfg.repositories;
            Type = "oneshot";
            UMask = "0077";
          };

          startLimitIntervalSec = 0;
        };
      };

      timers = {
        github-interaction-limits = {
          wantedBy = [
            "timers.target"
          ];

          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "15min";
          };
        };
      };
    };
  };
}
