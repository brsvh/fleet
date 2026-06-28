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
    initrd = {
      systemd = {
        enable = true;
      };
    };

    lanzaboote = {
      allowUnsigned = false;

      autoEnrollKeys = {
        allowBrickingMyMachine = true;
        autoReboot = false;
        enable = true;
        includeChecksumsFromTPM = false;
        includeMicrosoftKeys = false;
      };

      autoGenerateKeys = {
        enable = true;
      };

      configurationLimit = 8;
      enable = true;

      measuredBoot = {
        enable = true;
        pcrs = [
          0
          4
          7
        ];
      };

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
