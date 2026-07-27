{
  config,
  magnolia,
  ...
}:
{
  imports = [
    magnolia.profiles.sops
  ];

  services = {
    dae = {
      configFile =
        config.sops.secrets."config.dae".path;

      enable = true;
    };
  };

  sops = {
    secrets = {
      "config.dae" = {
        restartUnits = [
          "dae.service"
        ];
      };
    };
  };
}
