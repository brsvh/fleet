{
  azaleoid,
  config,
  system,
  ...
}:
{
  imports = [
    azaleoid.profiles.firewall
    azaleoid.profiles.sops
    system.profiles.harmonia
  ];

  services = {
    harmonia = {
      cache = {
        signKeyPaths = [
          config.sops.secrets."harmonia.txt".path
        ];
      };
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        5000
      ];
    };
  };

  sops = {
    secrets = {
      "harmonia.txt" = {
        restartUnits = [
          "harmonia.service"
        ];
      };
    };
  };
}
