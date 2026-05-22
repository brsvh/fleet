{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.offlineimap;

  offlineimapArgs = [
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

        package = mkOption {
          default = config.programs.offlineimap.package;

          description = ''
            OfflineIMAP package used by the systemd user service.
          '';

          type = types.package;
        };

        frequency = mkOption {
          default = "*:0/5";

          description = ''
            How often to run OfflineIMAP. This value is passed to the
            systemd user timer `OnCalendar` option.
          '';

          type = types.str;
        };

        ui = mkOption {
          default = "basic";

          description = ''
            OfflineIMAP user interface used by the systemd user service.
          '';

          type = types.str;
        };

        extraArgs = mkOption {
          default = [
            "-o"
          ];

          description = ''
            Extra arguments passed to OfflineIMAP by the systemd user service.
          '';

          type = with types; listOf str;
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
                "${cfg.package}/bin/offlineimap "
                + concatStringsSep " " offlineimapArgs;
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
