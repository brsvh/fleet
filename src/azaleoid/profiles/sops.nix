{
  system,
  ...
}:
{
  imports = [
    system.profiles.sops
  ];

  sops = {
    defaultSopsFile = azaleoid.etc.sops;
  };
}
