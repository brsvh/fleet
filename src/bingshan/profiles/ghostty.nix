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
    toString
    ;

  first = list: elemAt list 0;

  fonts = config.fonts.fontconfig.defaultFonts;
in
{
  imports = [
    bingshan.profiles.fonts
    home.profiles.ghostty
  ];

  programs = {
    ghostty = {
      settings = {
        font-family = "${first fonts.monospace}";
        font-size = config.gtk.font.size;
        theme = "Modus Vivendi Tinted";
      };
    };
  };
}
