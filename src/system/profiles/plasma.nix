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
}
