{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkForce
    ;
in
{
  imports = [
    system.profiles.systemd-boot
  ];

  boot = {
    loader = {
      efi = {
        efiSysMountPoint = mkForce "/efi";
      };
    };
  };
}
