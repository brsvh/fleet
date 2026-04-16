{
  lib,
  system,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.profiles.libvirt
  ];

  boot = {
    binfmt = {
      addEmulatedSystemsToNixSandbox = mkDefault false;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      qemu
    ];
  };

  systemd = {
    tmpfiles = {
      rules = [
        "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"
      ];
    };
  };

  virtualisation = {
    libvirtd = {
      qemu = {
        swtpm = {
          enable = mkDefault true;
        };
      };
    };

    spiceUSBRedirection = {
      enable = mkDefault true;
    };
  };
}
