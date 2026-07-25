{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (inputs)
    lanzaboote
    ;

  inherit (lib)
    mkForce
    ;
in
{
  imports = [
    lanzaboote.nixosModules.lanzaboote
    system.profiles.systemd-boot
  ];

  boot = {
    lanzaboote = {
      allowUnsigned = false;

      autoEnrollKeys = {
        allowBrickingMyMachine = false;
        autoReboot = false;
        enable = true;
        includeChecksumsFromTPM = false;
        includeMicrosoftKeys = true;
      };

      autoGenerateKeys = {
        enable = false;
      };

      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    loader = {
      efi = {
        efiSysMountPoint = mkForce "/efi";
      };

      systemd-boot = {
        enable = mkForce false;
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
    ];
  };
}
