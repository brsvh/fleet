{
  bingshan,
  home,
  ...
}:
{
  imports = [
    home.profiles.sops
  ];

  sops = {
    defaultSopsFile = bingshan.etc.sops;
  };
}
