{
  config,
  home,
  ...
}:
{
  imports = [
    home.profiles.npm
    home.profiles.xdg
  ];

  home = {
    sessionVariables = {
      NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
    };
  };

  xdg = {
    stateFile = {
      "node/.keep" = {
        text = ''
          This file is to keep the directory it belongs to exist.
        '';
      };
    };
  };
}
