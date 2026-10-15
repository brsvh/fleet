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
    system.modules.xkb
  ];

  services = {
    xserver = {
      xkb = {
        layout = mkDefault "us";
        options = mkDefault "compose:menu";
        variant = mkDefault "altgr-intl";
      };
    };
  };
}
