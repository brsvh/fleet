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
        olduse = {
          normalizeDuplicatePath = true;
          normalizeLegacyDate = true;
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
