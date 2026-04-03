{
  azaleoid,
  config,
  ...
}:
{
  imports = [
    azaleoid.profiles.sops
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
