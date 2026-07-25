{
  pkgs,
  ...
}:
{
  boot = {
    kernelModules = [
      "i2c-dev"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      openrgb
    ];
  };

  services = {
    udev = {
      packages = with pkgs; [
        openrgb
      ];
    };
  };
}
