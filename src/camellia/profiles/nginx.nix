{
  system,
  ...
}:
let
  archiveRoot = "/srv/archive";
  archivePublicRoot = "${archiveRoot}/public";
in
{
  imports = [
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        80
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "archive.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              extraConfig = ''
                autoindex on;
                disable_symlinks on;
                limit_except GET { deny all; }
              '';
            };
          };

          root = archivePublicRoot;
        };

        "assets.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              return = "404";
            };

            "~ \"^/chinese-fonts-overlay/images/([0-9a-f]{64}\\.webp)$\"" =
              {
                extraConfig = ''
                  set $preview_object $1;
                  limit_except GET HEAD { deny all; }
                  if ($request_uri !~ "^/chinese-fonts-overlay/images/[0-9a-f]{64}\.webp(?:\?retry=[0-9]+)?$") {
                    return 404;
                  }
                  proxy_pass http://127.0.0.1:3902/$preview_object;
                  proxy_http_version 1.1;
                  proxy_set_header Host chinese-fonts-overlay-previews.web.garage.internal;
                  proxy_set_header Connection "";
                  proxy_read_timeout 60s;
                  add_header Cache-Control "public, max-age=31536000, immutable";
                  add_header X-Content-Type-Options "nosniff" always;
                  add_header Cross-Origin-Resource-Policy "cross-origin" always;
                '';
              };
          };

          serverAliases = [
            "assets.brsvh.org"
          ];
        };

        "s3.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              return = "404";
            };

            "~ ^/chinese-fonts-overlay-(?:pages|previews|webfonts)(?:/|$)" =
              {
                extraConfig = ''
                  if ($request_uri !~ "^/chinese-fonts-overlay-(?:pages|previews|webfonts)(?:/|\?|$)") {
                    return 404;
                  }
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

  systemd = {
    tmpfiles = {
      rules = [
        # OpenSSH requires the chroot itself to be owned by root.
        "d ${archiveRoot} 0755 root root -"
        "d ${archivePublicRoot} 0755 archive archive -"
      ];
    };
  };
}
