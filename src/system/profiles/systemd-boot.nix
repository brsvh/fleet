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
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = mkDefault true;
        efiSysMountPoint = mkDefault "/boot/efi";
      };

      systemd-boot = {
        configurationLimit = mkDefault 10;
        enable = mkDefault true;
      };
    };
  };
}
