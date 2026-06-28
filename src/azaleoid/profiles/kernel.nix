{
  pkgs,
  ...
}:
{
  boot = {
    initrd = {
      verbose = false;
    };

    kernelPackages = pkgs.linuxPackages_zen;

    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
  };

  system = {
    boot = {
      loader = {
        kernelFile = "vmlinuz";
      };
    };
  };
}
