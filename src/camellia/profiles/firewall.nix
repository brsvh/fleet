{
  system,
  ...
}:
{
  imports = [
    system.profiles.firewall
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        22
      ];
    };
  };
}
