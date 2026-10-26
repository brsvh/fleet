{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.modules.ncps
  ];

  services = {
    ncps = {
      enable = mkDefault true;
      protectMigrations = mkDefault true;

      analytics = {
        reporting = {
          enable = mkDefault false;
        };
      };

      cache = {
        allowDeleteVerb = mkDefault false;

        lru = {
          schedule = mkDefault "*/5 * * * *";
          scheduleTimeZone = mkDefault "UTC";
        };

        signNarinfo = mkDefault true;

        upstream = {
          publicKeys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];

          urls = [
            "https://cache.nixos.org"
          ];
        };
      };

      server = {
        addr = mkDefault "127.0.0.1:8501";
      };
    };
  };
}
