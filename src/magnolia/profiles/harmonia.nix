{
  config,
  system,
  ...
}:
{
  imports = [
    system.profiles.harmonia
  ];

  services = {
    harmonia = {
      cache = {
        settings = {
          bind = "127.0.0.1:5000";
          priority = 30;
        };

        signKeyPaths = [
          config.sops.secrets.nix-cache-signing-key.path
        ];
      };
    };

    nginx = {
      virtualHosts = {
        ${config.networking.fqdn} = {
          onlySSL = true;
          useACMEHost = config.networking.fqdn;

          locations = {
            "/" = {
              extraConfig = ''
                proxy_buffering off;
              '';

              proxyPass = "http://127.0.0.1:5000";
            };
          };
        };
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
}
