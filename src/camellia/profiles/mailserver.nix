{
  camellia,
  config,
  system,
  ...
}:
{
  imports = [
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

        hashedPassword = "$y$j9T$f8cxmklj9ft1Sq6iZnMcM1$DnX/HiX8v384G5eUVCYChHxk44Z0348WP/s.btjRUH.";
      };
    };

    domains = [
      config.networking.domain
      "brsvh.org"
    ];

    fqdn = "mail.bingshan.org";
  };
}
