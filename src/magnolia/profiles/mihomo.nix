{
  config,
  magnolia,
  system,
  ...
}:
{
  imports = [
    magnolia.profiles.firewall
    magnolia.profiles.sops
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
        config.sops.secrets."mihomo.yaml".path;

      tunMode = true;
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
