{
  config,
  system,
  ...
}:
{
  imports = [
    system.profiles.harmonia
  ];

  networking = {
    firewall = {
      interfaces = {
        tailscale0 = {
          allowedTCPPorts = [
            5000
          ];
        };
      };
    };
  };

  services = {
    harmonia = {
      cache = {
        settings = {
          bind = "100.64.0.2:5000";
          priority = 30;
        };

        signKeyPaths = [
          config.sops.secrets.nix-cache-signing-key.path
        ];
      };
    };
  };

  sops = {
    secrets = {
      nix-cache-signing-key = {
        key = "nix-cache/signing-key";

        restartUnits = [
          "harmonia.service"
        ];
      };
    };
  };

  systemd = {
    sockets = {
      harmonia = {
        socketConfig = {
          FreeBind = true;
        };
      };
    };
  };
}
