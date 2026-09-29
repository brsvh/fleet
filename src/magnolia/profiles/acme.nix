{
  config,
  system,
  ...
}:
let
  domain = config.networking.fqdn;
in
{
  imports = [
    system.profiles.acme-cloudflare
  ];

  security = {
    acme = {
      certs = {
        ${domain} = {
          credentialFiles = {
            CF_DNS_API_TOKEN_FILE =
              config.sops.secrets.acme-cloudflare-api-token.path;
          };

          # dae intercepts DNS queries, including queries to authoritative servers.
          extraLegoFlags = [
            "--dns.propagation.wait"
            "60s"
          ];

          group = config.services.nginx.group;
        };
      };
    };
  };

  sops = {
    secrets = {
      acme-cloudflare-api-token = {
        key = "acme/cloudflare-api-token";

        restartUnits = [
          "acme-order-renew-${domain}.service"
        ];
      };
    };
  };

  systemd = {
    services = {
      "acme-order-renew-${domain}" = {
        after = [
          "sops-install-secrets.service"
        ];
      };
    };
  };
}
