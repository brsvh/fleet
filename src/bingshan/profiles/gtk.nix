{
  bingshan,
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    head
    mkForce
    ;

  fonts = config.fonts.fontconfig.defaultFonts;
in
{
  imports = [
    bingshan.profiles.fonts
    home.profiles.gtk
  ];

  gtk = {
    font = {
      name = mkForce (head fonts.sansSerif);
      package = mkForce null;
    };
  };
}
