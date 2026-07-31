{
  bingshan,
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    elemAt
    mkForce
    toString
    ;

  first = list: elemAt list 0;

  fonts = config.fonts.fontconfig.defaultFonts;
in
{
  imports = [
    bingshan.profiles.fonts
    home.profiles.gtk
  ];

  gtk = {
    font = {
      name = mkForce "${first fonts.sansSerif}";
      package = mkForce null;
    };
  };
}
