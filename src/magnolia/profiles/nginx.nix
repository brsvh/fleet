{
  system,
  ...
}:
{
  imports = [
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      interfaces = {
        tailscale0 = {
          allowedTCPPorts = [
            443
          ];
        };
      };
    };
  };

  services = {
    nginx = {
      defaultListenAddresses = [
        "100.64.0.2"
      ];

      recommendedProxySettings = true;
    };
  };

  systemd = {
    services = {
      nginx = {
        after = [
          "tailscaled.service"
          "tailscaled-autoconnect.service"
        ];

        wants = [
          "tailscaled.service"
        ];
      };
    };
  };
}
