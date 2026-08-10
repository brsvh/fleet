{
  azaleoid,
  config,
  system,
  ...
}:
{
  imports = [
    azaleoid.profiles.sops
    system.profiles.dae
  ];

  services = {
    dae = {
      configFile = config.sops.secrets."tagss.dae".path;
    };
  };

  sops = {
    secrets = {
      "tagss.dae" = {
        restartUnits = [
          "dae.service"
        ];
      };
    };
  };
}
