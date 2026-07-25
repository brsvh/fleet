{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.xdg)
    configHome
    ;

  inherit (lib)
    mkDefault
    ;

  ibm-plex-sans = pkgs.ibm-plex.override {
    families = [ "sans" ];
  };
in
{
  gtk = {
    enable = mkDefault true;

    font = {
      name = mkDefault "IBM Plex Sans";
      package = mkDefault ibm-plex-sans;
      size = mkDefault 11;
    };

    gtk2 = {
      configLocation = mkDefault "${configHome}/gtk-2.0/gtkrc";
    };
  };
}
