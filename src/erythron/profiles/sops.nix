{
  erythron,
  system,
  ...
}:
{
  imports = [
    system.profiles.sops
  ];

  sops = {
    defaultSopsFile = erythron.etc.sops;
  };
}
