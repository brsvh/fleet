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

  systemd = {
    services = {
      dae = {
        after = [
          "network-online.target"
        ];

        wants = [
          "network-online.target"
        ];
      };
    };
  };
}
