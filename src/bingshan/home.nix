{
  config,
  ...
}:
{
  home = {
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "26.05";
    username = "bingshan";
  };
}
