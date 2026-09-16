{
  config,
  magnolia,
  system,
  ...
}:
{
  imports = [
    system.profiles.inn
  ];

  services = {
    inn = {
      credentials = {
        eternal-september =
          config.sops.secrets.inn-eternal-september.path;
        solani = config.sops.secrets.inn-solani.path;
      };

      peers = {
        azaleoid = {
          address = "100.64.0.3";
          host = "azaleoid.tail.bingshan.org";
        };

        erythron = {
          address = "100.64.0.4";
          host = "erythron.tail.bingshan.org";
        };
      };

      recent = {
        enable = true;
      };

      role = "primary";

      upstreams = {
        eternal-september = {
          endpoint = "news.eternal-september.org:563_TLS";
          passwordCredential = "eternal-september";
          username = "bingshan";
        };

        gmane = {
          endpoint = "news.gmane.io:119_STARTTLS";
        };

        olduse = {
          endpoint = "olduse.net:11940";
          normalizeDuplicatePath = true;
          normalizeLegacyDate = true;
        };

        solani = {
          endpoint = "news.solani.org:563_TLS";
          passwordCredential = "solani";
          username = "bingshan";
        };
      };
    };
  };

  sops = {
    secrets = {
      inn-eternal-september = {
        key = "eternal-september";
        sopsFile = magnolia.etc."inn.sops";
      };

      inn-solani = {
        key = "solani";
        sopsFile = magnolia.etc."inn.sops";
      };
    };
  };
}
