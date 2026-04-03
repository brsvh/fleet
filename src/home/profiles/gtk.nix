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
in
{
  gtk = {
    gtk2 = {
      configLocation = mkDefault "${configHome}/gtk-2.0/gtkrc";
    };
  };
}
