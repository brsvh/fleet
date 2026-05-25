{
  camellia,
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    genAttrs
    ;

  inherit (pkgs)
    writeTextDir
    ;

  cfg = config.mailserver;

  mtaSts = {
    host = {
      enableACME = config.security.acme.acceptTerms;
      forceSSL = config.security.acme.acceptTerms;

      root = writeTextDir ".well-known/mta-sts.txt" ''
        version: STSv1
        mode: testing
        mx: ${cfg.fqdn}
        max_age: 604800
      '';

      locations = {
        "= /.well-known/mta-sts.txt" = {
          extraConfig = ''
            default_type text/plain;
          '';
        };
      };
    };
  };

  mtaStsVirtualHosts = genAttrs (map (
    domain: "mta-sts.${domain}"
  ) cfg.domains) (_: mtaSts.host);
in
{
  imports = [
    camellia.profiles.sops
    camellia.profiles.networking
    system.profiles.mailserver
  ];

  mailserver = {
    accounts = {
      "chang@bingshan.org" = {
        aliases = [
          "abuse@brsvh.org"
          "bot@brsvh.org"
          "bsc@brsvh.org"
          "open@brsvh.org"
          "postmaster@brsvh.org"
          "register@brsvh.org"
          "steam@brsvh.org"
        ];

        passwordFile =
          config.sops.secrets."chang@bingshan.org".path;
      };

      "cloud@bingshan.org" = {
        passwordFile =
          config.sops.secrets."cloud@bingshan.org".path;

        sendOnly = true;
      };
    };

    domains = [
      config.networking.domain
      "brsvh.org"
    ];

    fqdn = "mail.bingshan.org";
  };

  services = {
    nginx = {
      virtualHosts = mtaStsVirtualHosts;
    };
  };

  sops = {
    secrets = {
      "chang@bingshan.org" = {
        restartUnits = [
          "dovecot.service"
        ];
      };

      "cloud@bingshan.org" = {
        restartUnits = [
          "dovecot.service"
        ];
      };
    };
  };
}
