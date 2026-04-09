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
      enable = mkDefault true;
      createDirectories = mkDefault true;
      desktop = "${dataHome}/Desktop";
      documents = "${dataHome}/Documents";
      download = "${dataHome}/Downloads";
      music = "${dataHome}/Music";
      pictures = "${dataHome}/Pictures";
      publicShare = "${dataHome}/Public";
      setSessionVariables = mkDefault true;
      templates = "${dataHome}/Templates";
      videos = "${dataHome}/Videos";
    };
  };
}
