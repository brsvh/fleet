{
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      liquidctl
    ];
  };

  services = {
    udev = {
      packages = with pkgs; [
        liquidctl
      ];
    };
  };
}
