{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    getExe
    hasPrefix
    mkEnableOption
    mkForce
    mkIf
    removePrefix
    ;

  cfg = config.services.ncps;
  database = cfg.cache.databaseURL;
  sqlite =
    database != null && hasPrefix "sqlite:/" database;
in
{
  options = {
    services = {
      ncps = {
        protectMigrations = mkEnableOption "ncps SQLite migration preflight and backups";
      };
    };
  };

  config =
    mkIf (cfg.enable && cfg.protectMigrations)
      {
        assertions = [
          {
            assertion =
              sqlite && cfg.cache.databaseURLFile == null;

            message = ''
              ncps migration protection requires an explicit local SQLite database URL.
            '';
          }
        ];

        systemd = {
          services = {
            ncps = {
              # Replace the upstream unguarded migrate command, not just prepend it.
              preStart = mkForce ''
                ${getExe pkgs.python3} ${./ncps-migrate.py} \
                  ${escapeShellArg (getExe cfg.package)} \
                  ${escapeShellArg (
                    removePrefix "sqlite:" database
                  )}
              '';
            };
          };
        };
      };
}
