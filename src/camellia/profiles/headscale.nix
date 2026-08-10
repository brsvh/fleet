{
  camellia,
  system,
  ...
}:
{
  imports = [
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        443
      ];

      allowedUDPPorts = [
        3478
      ];
    };
  };

  services = {
    headscale = {
      enable = true;

      settings = {
        auto_update = {
          enabled = false;
        };

        derp = {
          auto_update_enabled = true;

          server = {
            automatically_add_embedded_derp_region = true;

            enabled = true;
            ipv4 = "95.133.228.83";
            ipv6 = "2a0b:7140:8:1:5054:ff:feef:6795";
            region_code = "camellia";
            region_id = 999;
            region_name = "Camellia";
            stun_listen_addr = "0.0.0.0:3478";
            verify_clients = true;
          };

          update_frequency = "3h";

          urls = [
            "https://controlplane.tailscale.com/derpmap/default"
          ];
        };

        dns = {
          base_domain = "tail.bingshan.org";
          magic_dns = true;
          override_local_dns = false;
        };

        grpc_allow_insecure = false;
        grpc_listen_addr = "127.0.0.1:50443";

        logtail = {
          enabled = false;
        };

        metrics_listen_addr = "127.0.0.1:9090";

        node = {
          expiry = 0;
        };

        policy = {
          mode = "file";
          path = camellia.etc.headscale.policy;
        };

        server_url = "https://head.bingshan.org";

        taildrop = {
          enabled = false;
        };

        trusted_proxies = [
          "127.0.0.1/32"
        ];

        unix_socket_permission = "0770";
      };
    };

    nginx = {
      virtualHosts = {
        "head.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "= /generate_204" = {
              extraConfig = ''
                return 204;
              '';
            };

            "/" = {
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header True-Client-IP $remote_addr;
              '';

              proxyPass = "http://127.0.0.1:8080";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
}
