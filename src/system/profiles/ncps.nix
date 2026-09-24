{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  services = {
    ncps = {
      enable = mkDefault true;

      analytics = {
        reporting = {
          enable = mkDefault false;
        };
      };

      cache = {
        allowDeleteVerb = mkDefault false;
        signNarinfo = mkDefault true;

        lru = {
          schedule = mkDefault "*/5 * * * *";
          scheduleTimeZone = mkDefault "UTC";
        };

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
