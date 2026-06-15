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
        cursor-style = "block";
        font-family = "${first fonts.monospace}";
        font-size = config.gtk.font.size;
        shell-integration-features = "no-cursor,ssh-env,ssh-terminfo,sudo,title";
        theme = "Modus Vivendi Tinted";
      };
    };
  };
}
