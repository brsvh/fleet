{
  config,
  ...
}:
{
  home = {
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "25.11";
    username = "bingshan";
  };
}
