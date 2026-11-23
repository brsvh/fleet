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

  siteBucket = "chinese-fonts-overlay-site";
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
          ${siteBucket} = {
            keys = {
              site-reader = false;
              site-writer = true;
            };

            maximumSize = 2147483648;
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

          site-reader = {
            id = "GK193986f86cce1b74eaf6a849";
            secretFile = secrets."garage/site-reader".path;
          };

          site-writer = {
            id = "GK034518f6cbd60752ae8314fb";
            secretFile = secrets."garage/site-writer".path;
          };
        };

        rpcSecretFile = secrets."garage/rpc-secret".path;
        zone = "camellia";
      };
    };
  };

  sops = {
    secrets = {
      "garage/rpc-secret" = {
        owner = "garage";

        restartUnits = [
          "garage.service"
          "garage-configure.service"
        ];
      };

      "garage/site-reader" = {
        restartUnits = [
          "garage-configure.service"
        ];
      };

      "garage/site-writer" = {
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
          ${config.services.garage.package}/bin/garage \
            --rpc-secret-file "$CREDENTIALS_DIRECTORY/rpc-secret" \
            bucket cleanup-incomplete-uploads --older-than 1d ${siteBucket}
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
