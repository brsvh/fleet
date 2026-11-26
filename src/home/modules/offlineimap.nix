{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    mkEnableOption
    mkIf
    mkOption
    replaceStrings
    types
    ;

  cfg = config.services.offlineimap;

  escapeSystemdArg =
    argument:
    "\"${
      replaceStrings
        [
          "\\"
          "\""
          "%"
          "\n"
        ]
        [
          "\\\\"
          "\\\""
          "%%"
          "\\n"
        ]
        argument
    }\"";

  offlineimapArgs = [
    "${cfg.package}/bin/offlineimap"
    "-u"
    cfg.ui
  ]
  ++ cfg.extraArgs;
in
{
  options = {
    services = {
      offlineimap = {
        enable = mkEnableOption "OfflineIMAP synchronization";

        extraArgs = mkOption {
          default = [
            "-o"
          ];

          description = ''
            Extra arguments passed to OfflineIMAP by the systemd user service.
          '';

          type = with types; listOf str;
        };

        frequency = mkOption {
          default = "*:0/5";

          description = ''
            How often to run OfflineIMAP. This value is passed to the
            systemd user timer `OnCalendar` option.
          '';

          type = types.str;
        };

        package = mkOption {
          default = config.programs.offlineimap.package;

          description = ''
            OfflineIMAP package used by the systemd user service.
          '';

          type = types.package;
        };

        ui = mkOption {
          default = "basic";

          description = ''
            OfflineIMAP user interface used by the systemd user service.
          '';

          type = types.str;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      user = {
        services = {
          offlineimap = {
            Service = {
              ExecStart =
                concatMapStringsSep " " escapeSystemdArg
                  offlineimapArgs;
              Type = "oneshot";
            };

            Unit = {
              Description = "OfflineIMAP sync";
            };
          };
        };

        timers = {
          offlineimap = {
            Install = {
              WantedBy = [
                "timers.target"
              ];
            };

            Timer = {
              OnCalendar = cfg.frequency;
              Unit = "offlineimap.service";
            };

            Unit = {
              Description = "OfflineIMAP sync";
            };
          };
        };
      };
    };
  };
}
