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

        "s3.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              return = "404";
            };

            "~ ^/chinese-fonts-overlay-(?:pages|webfonts)(?:/|$)" =
              {
                extraConfig = ''
                  if ($request_uri !~ "^/chinese-fonts-overlay-(?:pages|webfonts)(?:/|\?|$)") {
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
