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
