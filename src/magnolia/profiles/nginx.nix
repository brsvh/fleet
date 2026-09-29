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
        # Match the local FQDN entry in /etc/hosts.
        "127.0.0.2"
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
