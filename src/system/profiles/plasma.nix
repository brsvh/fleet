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
    desktopManager = {
      plasma6 = {
        enable = mkDefault true;
      };
    };
  };

  systemd = {
    user = {
      services = {
        kde-baloo = {
          overrideStrategy = "asDropin";

          serviceConfig = {
            IOAccounting = mkDefault true;
          };
        };
      };
    };
  };
}
