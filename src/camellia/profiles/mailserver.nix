{
  camellia,
  config,
  system,
  ...
}:
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
