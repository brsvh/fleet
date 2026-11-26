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
      interfaces = {
        tailscale0 = {
          allowedTCPPorts = [
            3389
          ];
        };
      };
    };
  };
}
