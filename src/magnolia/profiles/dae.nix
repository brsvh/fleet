{
  config,
  magnolia,
  system,
  ...
}:
{
  imports = [
    magnolia.profiles.sops
    system.profiles.dae
  ];

  services = {
    dae = {
      configFile =
        config.sops.secrets."config.dae".path;
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
