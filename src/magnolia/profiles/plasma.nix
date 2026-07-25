{
  pkgs,
  system,
  ...
}:
{
  imports = [
    system.profiles.plasma
  ];

  environment = {
    plasma6 = {
      excludePackages = with pkgs.kdePackages; [
        kate
      ];
    };
  };
}
