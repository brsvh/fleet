{
  camellia,
  config,
  ...
}:
let
  inherit (config.sops)
    secrets
    ;

  bucket = "chinese-fonts-overlay-site";
  readerId = "GK193986f86cce1b74eaf6a849";
  writerId = "GK034518f6cbd60752ae8314fb";
in
{
  imports = [
    camellia.profiles.garage
    camellia.profiles.nginx
  ];

  services = {
    garage = {
      provision = {
        buckets = {
          ${bucket} = {
            keys = {
              site-reader = false;
              site-writer = true;
            };

            maximumSize = 2147483648;
          };
        };

        keys = {
          site-reader = {
            id = readerId;
            secretFile = secrets."garage/site-reader".path;
          };

          site-writer = {
            id = writerId;
            secretFile = secrets."garage/site-writer".path;
          };
        };
      };
    };

    nginx = {
      virtualHosts = {
        "s3.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              return = "404";
            };

            "~ ^/${bucket}(?:/|$)" = {
              extraConfig = ''
                client_max_body_size 1000m;
                client_body_timeout 300s;
                proxy_pass http://127.0.0.1:3900;
                proxy_http_version 1.1;
                proxy_set_header Host $host;
                proxy_set_header Connection "";
                proxy_request_buffering off;
                proxy_buffering off;
                proxy_max_temp_file_size 0;
                proxy_read_timeout 300s;
                proxy_send_timeout 300s;
              '';
            };
          };
        };
      };
    };
  };

  sops = {
    secrets = {
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
            bucket cleanup-incomplete-uploads --older-than 1d ${bucket}
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
