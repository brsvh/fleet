{
  bingshan,
  config,
  home,
  ...
}:
{
  imports = [
    bingshan.profiles.sops
    home.profiles.inn
  ];

  services = {
    inn = {
      credentialService = "sops-nix.service";
      domain = "bingshan.org";

      backfill = {
        maxArticlesPerGroup = 1000;
        maxRunSeconds = 600;
        syncInterval = "15m";
      };

      organization = "Bingshan's local news archive";
      pathHost = "news.bingshan.org";

      recent = {
        enable = true;
        lookbackDays = 7;
        maxArticlesPerGroup = 1000;
        syncInterval = "5m";
      };

      credentials = {
        "eternal-september" =
          config.sops.secrets."eternal-september".path;

        "solani" = config.sops.secrets."solani".path;
      };
    };
  };

  sops = {
    secrets = {
      "eternal-september" = { };

      "solani" = { };
    };
  };
}
