{
  config,
  system,
  ...
}:
let
  inherit (config.sops)
    secrets
    ;
in
{
  imports = [
    system.profiles.ncps
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        443
      ];
    };
  };

  services = {
    ncps = {
      cache = {
        allowPutVerb = true;
        hostName = "cache.bingshan.org";
        maxSize = "21474836480B";
        secretKeyPath =
          secrets.nix-cache-signing-key.path;
        tempPath = "/var/lib/ncps/tmp";
      };
    };

    nginx = {
      virtualHosts = {
        "cache.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              # The upload namespace never fetches unselected upstream paths.
              proxyPass = "http://127.0.0.1:8501/upload/";

              extraConfig = ''
                client_max_body_size 20G;
                proxy_request_buffering off;
                proxy_buffering off;
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;

                limit_except GET {
                  auth_basic "Nix cache publication";
                  auth_basic_user_file ${secrets.nix-cache-upload-htpasswd.path};
                }
              '';
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
          "ncps.service"
        ];
      };

      nix-cache-upload-htpasswd = {
        key = "nix-cache/upload-htpasswd";
        owner = "nginx";
      };
    };
  };
}
