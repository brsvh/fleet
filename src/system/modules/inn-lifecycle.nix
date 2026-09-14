{
  archiveTool,
  cfg,
  groups,
  innEnvironment,
  lib,
  pkgs,
  preStart,
}:
let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    escapeShellArgs
    makeBinPath
    mapAttrsToList
    mkIf
    mkMerge
    optional
    optionalString
    pipe
    ;

  primary = cfg.role == "primary";
  state = cfg.stateDirectory;
  seed = "/var/lib/inn-bootstrap/seed";
  marker = "${state}/.initialized";
  path = makeBinPath (
    with pkgs;
    [
      coreutils
      diffutils
      findutils
      jq
      procps
      rsync
      systemd
      util-linux
    ]
  );

  prepare = pkgs.writeShellScript "inn-prepare" ''
    set -euo pipefail
    export PATH=${path}
    ${optionalString (cfg.legacyUser != null) ''
      legacy_user=${escapeShellArg cfg.legacyUser}
      legacy_uid="$(id -u "$legacy_user")"
      if systemctl is-active --quiet "user@$legacy_uid.service"; then
        userctl() {
          runuser -u "$legacy_user" -- env \
            XDG_RUNTIME_DIR="/run/user/$legacy_uid" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$legacy_uid/bus" \
            ${pkgs.systemd}/bin/systemctl --user "$@"
        }
        for unit in inn-news-recent.timer inn-news-live.timer \
          inn-news-backfill.timer inn-news-retry.timer \
          inn-news-recent.service inn-news-live.service \
          inn-news-backfill.service inn-news-retry.service \
          inn-news-backfill-check.service inn.service; do
          if [[ "$(userctl show --property=LoadState --value "$unit")" != not-found ]]; then
            userctl stop "$unit"
          fi
        done
      fi
      if pgrep -u "$legacy_uid" -x innd >/dev/null; then
        echo "An INN process still runs as $legacy_user; refusing migration" >&2
        exit 1
      fi
    ''}

    state=${escapeShellArg state}
    if test -f "$state/.initialized"; then
      jq -e --arg primary ${escapeShellArg cfg.primaryHost} \
        --arg role ${escapeShellArg cfg.role} \
        '.primary == $primary and .role == $role' \
        "$state/.initialized" >/dev/null
    elif test -d "$state" && test -n "$(find "$state" -mindepth 1 -maxdepth 1 -print -quit)"; then
      echo "Unrecognized existing system INN data: $state; refusing to overwrite" >&2
      exit 1
    else
      ${
        if primary then
          ''
            if systemctl is-active --quiet inn.service; then
              echo "Cannot initialize an active archive" >&2
              exit 1
            fi
            stage="$state.migrating"
            install -d -m 0750 "$stage"
            ${optionalString (cfg.migrateFrom != null) ''
              source=${escapeShellArg cfg.migrateFrom}
              test -s "$source/db/active"
              test -s "$source/db/history"
              test -d "$source/spool/articles"
              exec 8>"$source/pullnews.lock"
              exec 9>"$source/inventory.lock"
              flock -n 8
              flock -n 9
              shopt -s dotglob nullglob
              for entry in "$source"/*; do
                if [[ "$(basename "$entry")" != run ]]; then
                  cp -a --reflink=auto "$entry" "$stage/"
                fi
              done
              # Content verification happens before changing ownership or initialization.
              differences="$(rsync -rHnci --delete --exclude=/run/ "$source/" "$stage/")"
              if test -n "$differences"; then
                echo "Archive copy differs from its stopped source:" >&2
                echo "$differences" >&2
                exit 1
              fi
            ''}
            jq -n --arg primary ${escapeShellArg cfg.primaryHost} \
              --arg id "$(cat /proc/sys/kernel/random/uuid)" \
              '{primary: $primary, role: "primary", archive_id: $id}' \
              > "$stage/.initialized"
            chown -R ${escapeShellArg "${cfg.user}:${cfg.group}"} "$stage"
            if test -d "$state"; then rmdir "$state"; fi
            mv "$stage" "$state"
          ''
        else
          ''
            install -d -m 0750 -o ${escapeShellArg cfg.user} -g ${escapeShellArg cfg.group} "$state"
          ''
      }
    fi

    ${optionalString primary ''
      if ! test -s ${seed}/seed.json; then
        if systemctl is-active --quiet inn.service; then
          echo "Cannot snapshot a running INN archive" >&2
          exit 1
        fi
        runuser -u ${escapeShellArg cfg.user} -- env \
          ${escapeShellArgs innEnvironment} ${preStart}
        install -d -m 0750 -o ${escapeShellArg cfg.user} -g ${escapeShellArg cfg.group} \
          /var/lib/inn-bootstrap /var/lib/inn-bootstrap/staging
        snapshot=/var/lib/inn-bootstrap/staging
        cp -a --reflink=auto "$state/db" "$snapshot/"
        install -d -m 0750 "$snapshot/spool"
        cp -a --reflink=auto "$state/spool/articles" "$state/spool/overview" "$snapshot/spool/"
        ${archiveTool}/bin/inn-archive seed-manifest --directory "$snapshot"
        chown -R ${escapeShellArg "${cfg.user}:${cfg.group}"} "$snapshot"
        mv "$snapshot" ${seed}
      fi
    ''}
  '';

  bootstrapCheck = pkgs.writeShellScript "inn-bootstrap-check" ''
    set -euo pipefail
    export PATH=${path}
    if ! ${archiveTool}/bin/inn-archive primary-ready; then
      echo "Waiting for ${cfg.primaryHost} to become ready"
      exit 1
    fi
    install -d -m 0750 ${escapeShellArg "${state}.bootstrap"}
    if ! rsync --ipv4 --timeout=30 --contimeout=10 \
      rsync://${cfg.primaryHost}:${toString cfg.bootstrapPort}/inn/seed.json \
      ${escapeShellArg "${state}.bootstrap/seed.json"}; then
      echo "Waiting for the primary bootstrap export"
      exit 1
    fi
    ${archiveTool}/bin/inn-archive validate-seed --directory ${escapeShellArg "${state}.bootstrap"}
  '';

  bootstrap = pkgs.writeShellScript "inn-bootstrap" ''
    set -euo pipefail
    export PATH=${path}
    stage=${escapeShellArg "${state}.bootstrap"}
    if ! rsync --archive --hard-links --no-owner --no-group \
      --partial --delete-delay --ipv4 --timeout=60 --contimeout=10 \
      rsync://${cfg.primaryHost}:${toString cfg.bootstrapPort}/inn/ "$stage/"; then
      echo "Bootstrap interrupted; retaining partial files for retry"
      exit 0
    fi
    ${archiveTool}/bin/inn-archive validate-seed --full --directory "$stage"
    chown -R ${escapeShellArg "${cfg.user}:${cfg.group}"} "$stage"
    rmdir ${escapeShellArg state}
    mv "$stage" ${escapeShellArg state}
    systemctl --no-block start inn.service
  '';

  rsyncConfiguration = pkgs.writeText "inn-bootstrap-rsyncd.conf" ''
    address = 0.0.0.0
    port = ${toString cfg.bootstrapPort}
    use chroot = false
    read only = true
    reverse lookup = false
    hosts allow = ${
      pipe cfg.peers [
        (mapAttrsToList (_: peer: peer.address))
        (concatStringsSep " ")
      ]
    }
    hosts deny = *
    [inn]
    path = ${seed}
    list = false
    transfer logging = true
  '';
in
mkMerge [
  {
    assertions = [
      {
        assertion = state == "/var/lib/inn";
        message = "System INN migration and bootstrap use /var/lib/inn.";
      }
      {
        assertion =
          primary
          || (
            cfg.upstreams == { }
            && cfg.peers == { }
            && cfg.migrateFrom == null
          );
        message = "INN replicas must only receive articles from their primary.";
      }
      {
        assertion = groups != [ ];
        message = "INN requires at least one configured article group.";
      }
    ];

    systemd = {
      services = {
        inn-prepare = {
          after = optional (
            cfg.legacyUser != null
          ) "home-manager-${cfg.legacyUser}.service";

          before = [
            "inn.service"
          ];

          description = "Prepare INN state and retire legacy user units";

          serviceConfig = {
            ExecStart = prepare;
            RemainAfterExit = true;
            TimeoutStartSec = "infinity";
            Type = "oneshot";
            UMask = "0027";
          };

          unitConfig = {
            RequiresMountsFor = [
              state
            ]
            ++ optional (
              cfg.migrateFrom != null
            ) cfg.migrateFrom;
          };

          wantedBy = [
            "multi-user.target"
          ];
        };
      };
    };
  }
  (mkIf primary {
    systemd = {
      services = {
        inn-bootstrap-export = {
          after = [
            "inn.service"
          ];

          bindsTo = [
            "inn.service"
          ];

          description = "Export the immutable INN bootstrap image over the tailnet";

          partOf = [
            "inn.service"
          ];

          serviceConfig = {
            ExecStart = "${pkgs.rsync}/bin/rsync --daemon --no-detach --config=${rsyncConfiguration}";
            Group = cfg.group;
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            Restart = "on-failure";
            RestartSec = "5s";
            User = cfg.user;
          };

          unitConfig = {
            ConditionPathExists = "${seed}/seed.json";
          };

          wantedBy = [
            "inn.service"
          ];
        };
      };
    };
  })
  (mkIf (!primary) {
    systemd = {
      services = {
        inn-bootstrap = {
          after = [
            "network-online.target"
            "tailscaled.service"
            "inn-prepare.service"
          ];

          description = "Initialize the replica when the primary is ready";

          requires = [
            "inn-prepare.service"
          ];

          serviceConfig = {
            ExecCondition = bootstrapCheck;
            ExecStart = bootstrap;
            TimeoutStartSec = "infinity";
            Type = "oneshot";
            UMask = "0027";
          };

          unitConfig = {
            ConditionPathExists = "!${marker}";
          };

          wantedBy = [
            "multi-user.target"
          ];

          wants = [
            "network-online.target"
            "tailscaled.service"
          ];
        };
      };

      timers = {
        inn-bootstrap = {
          description = "Retry pending INN initialization";

          timerConfig = {
            OnBootSec = "1m";
            OnUnitInactiveSec = "1m";
          };

          wantedBy = [
            "timers.target"
          ];
        };
      };
    };
  })
]
