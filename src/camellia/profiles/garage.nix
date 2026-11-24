{
  camellia,
  config,
  pkgs,
  system,
  ...
}:
let
  inherit (config.sops)
    secrets
    ;

  pagesBucket = "chinese-fonts-overlay-pages";
  webfontsBucket = "chinese-fonts-overlay-webfonts";
in
{
  imports = [
    camellia.profiles.sops
    system.modules.garage-provision
    system.profiles.garage
  ];

  services = {
    garage = {
      environmentFile = pkgs.writeText "garage.env" ''
        GARAGE_RPC_SECRET_FILE=${
          secrets."garage/rpc-secret".path
        }
      '';

      provision = {
        buckets = {
          ${pagesBucket} = {
            keys = {
              pages-reader = false;
              pages-writer = true;
            };

            maximumSize = 2147483648;
          };

          ${webfontsBucket} = {
            keys = {
              webfonts-reader = false;
              webfonts-writer = true;
            };

            maximumSize = 536870912;
          };

          nextcloud = {
            keys = {
              nextcloud = true;
            };
          };
        };

        capacity = 53687091200;
        enable = true;

        keys = {
          nextcloud = {
            id = "GK74f5107bc2ede82b9f049e23";
            secretFile =
              secrets."nextcloud/s3-secret-key".path;
          };

          pages-reader = {
            id = "GK31e4112f2e0d1388165df6f3";
            secretFile = secrets."garage/pages-reader".path;
          };

          pages-writer = {
            id = "GKe25af8c7d4e8d1115e0ea42e";
            secretFile = secrets."garage/pages-writer".path;
          };

          webfonts-reader = {
            id = "GKeb46e862f6527c06f15e2c84";
            secretFile =
              secrets."garage/webfonts-reader".path;
          };

          webfonts-writer = {
            id = "GK25386caffcf8f3e51f8505cf";
            secretFile =
              secrets."garage/webfonts-writer".path;
          };
        };

        rpcSecretFile = secrets."garage/rpc-secret".path;
        zone = "camellia";
      };
    };
  };

  sops = {
    secrets = {
      "garage/pages-reader" = {
        restartUnits = [
          "garage-configure.service"
        ];
      };

      "garage/pages-writer" = {
        restartUnits = [
          "garage-configure.service"
        ];
      };

      "garage/rpc-secret" = {
        owner = "garage";

        restartUnits = [
          "garage.service"
          "garage-configure.service"
        ];
      };

      "garage/webfonts-reader" = {
        restartUnits = [
          "garage-configure.service"
        ];
      };

      "garage/webfonts-writer" = {
        restartUnits = [
          "garage-configure.service"
        ];
      };
    };
  };

  systemd = {
    services = {
      garage-configure = {
        before = [
          "nextcloud-setup.service"
        ];
      };

      garage-upload-cleanup = {
        after = [
          "garage-configure.service"
        ];

        requires = [
          "garage.service"
        ];

        script = ''
          for bucket in ${pagesBucket} ${webfontsBucket}; do
            ${config.services.garage.package}/bin/garage \
              --rpc-secret-file "$CREDENTIALS_DIRECTORY/rpc-secret" \
              bucket cleanup-incomplete-uploads --older-than 1d "$bucket"
          done
        '';

        serviceConfig = {
          Group = "garage";

          LoadCredential = [
            "rpc-secret:${secrets."garage/rpc-secret".path}"
          ];

          Type = "oneshot";
          User = "garage";
        };
      };
    };

    timers = {
      garage-upload-cleanup = {
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };

        wantedBy = [
          "timers.target"
        ];
      };
    };
  };
}
