{
  system,
  ...
}:
{
  imports = [
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        80
      ];
    };
  };
}
