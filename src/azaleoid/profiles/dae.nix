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
      configFile = config.sops.secrets."dae.dae".path;

      enable = true;
    };
  };

  sops = {
    secrets = {
      "dae.dae" = {
        restartUnits = [
          "dae.service"
        ];
      };
    };
  };
}
