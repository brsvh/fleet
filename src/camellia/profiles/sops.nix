{
  camellia,
  system,
  ...
}:
{
  imports = [
    system.profiles.sops
  ];

  sops = {
    defaultSopsFile = camellia.etc.sops;
  };
}
