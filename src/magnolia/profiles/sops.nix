{
  magnolia,
  system,
  ...
}:
{
  imports = [
    system.profiles.sops
  ];

  sops = {
    defaultSopsFile = magnolia.etc.sops;
  };
}
