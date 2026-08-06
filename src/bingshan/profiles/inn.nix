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
      maxArticlesPerGroup = 500;
      maxRunSeconds = 600;
      organization = "Bingshan's local news archive";
      pathHost = "news.bingshan.org";
      syncInterval = "30m";

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
