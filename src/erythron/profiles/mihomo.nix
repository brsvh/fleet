{
  config,
  erythron,
  system,
  ...
}:
{
  imports = [
    erythron.profiles.firewall
    erythron.profiles.sops
    system.profiles.mihomo
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        7890
      ];

      allowedUDPPorts = [
        7890
      ];
    };
  };

  services = {
    mihomo = {
      configFile =
        config.sops.secrets."tagss.yaml".path;

      tunMode = false;
    };
  };

  sops = {
    secrets = {
      "tagss.yaml" = {
        restartUnits = [
          "mihomo.service"
        ];
      };
    };
  };
}
