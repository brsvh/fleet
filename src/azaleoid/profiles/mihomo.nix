{
  azaleoid,
  config,
  system,
  ...
}:
{
  imports = [
    azaleoid.profiles.sops
    system.profiles.mihomo
  ];

  services = {
    mihomo = {
      configFile =
        config.sops.secrets."mihomo.yaml".path;
    };
  };

  sops = {
    secrets = {
      "mihomo.yaml" = {
        restartUnits = [
          "mihomo.service"
        ];
      };
    };
  };
}
