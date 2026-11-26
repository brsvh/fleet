{
  config,
  lib,
  ...
}:
let
  inherit (config.xdg)
    dataHome
    ;

  inherit (lib)
    mkDefault
    ;
in
{
  home = {
    preferXdgDirectories = mkDefault true;
  };

  xdg = {
    enable = mkDefault true;

    mimeApps = {
      enable = mkDefault true;
    };

    userDirs = {
      createDirectories = mkDefault true;
      desktop = "${dataHome}/Desktop";
      documents = "${dataHome}/Documents";
      download = "${dataHome}/Downloads";
      enable = mkDefault true;
      music = "${dataHome}/Music";
      pictures = "${dataHome}/Pictures";
      projects = config.home.homeDirectory;
      publicShare = "${dataHome}/Public";
      setSessionVariables = mkDefault true;
      templates = "${dataHome}/Templates";
      videos = "${dataHome}/Videos";
    };
  };
}
