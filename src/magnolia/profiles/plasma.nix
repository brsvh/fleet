{
  magnolia,
  pkgs,
  system,
  ...
}:
{
  imports = [
    magnolia.profiles.firewall
    system.profiles.plasma
  ];

  environment = {
    plasma6 = {
      excludePackages = with pkgs.kdePackages; [
        kate
      ];
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        3389
      ];
    };
  };
}
