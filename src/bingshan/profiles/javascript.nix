{
  home,
  ...
}:
{
  imports = [
    home.profiles.bun
    home.profiles.node
    home.profiles.xdg
  ];

  home = {
    sessionVariables = {
      NODE_REPL_HISTORY_SIZE = 10000;
    };
  };
}
