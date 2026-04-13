{
  azaleoid,
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
    bingshan.profiles.gtk
    home.profiles.gnome
    home.profiles.xdg
  ];

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        font-name = "${first fonts.sansSerif} ${toString config.gtk.font.size}";
        document-font-name = "${first fonts.serif} ${toString config.gtk.font.size}";
        monospace-font-name = "${first fonts.monospace} ${toString config.gtk.font.size}";
      };

      "org/gnome/desktop/session" = {
        idle-delay = 0;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        sleep-inactive-ac-type = "nothing";
      };
    };
  };

  xdg = {
    configFile = {
      "monitors.xml" = {
        source = azaleoid.etc.monitors;
      };
    };
  };
}
