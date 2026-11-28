{
  config,
  ...
}:
{
  home = {
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "26.11";
    username = "ops";
  };
}
