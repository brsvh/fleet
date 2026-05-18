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
        hashedPassword = "$y$j9T$f8cxmklj9ft1Sq6iZnMcM1$DnX/HiX8v384G5eUVCYChHxk44Z0348WP/s.btjRUH.";
      };
    };

    domains = [
      config.networking.domain
    ];

    fqdn = config.networking.fqdn;
  };
}
