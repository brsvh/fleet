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
    ;

  first = list: elemAt list 0;

  fontFamilies =
    config.fonts.fontconfig.defaultFonts;

  fontSize = config.gtk.font.size;

  fixedWidthFont = {
    family = first fontFamilies.monospace;
    pointSize = fontSize;
  };

  generalFont = {
    family = first fontFamilies.sansSerif;
    pointSize = fontSize;
  };
in
{
  imports = [
    bingshan.profiles.fonts
    bingshan.profiles.gtk
    home.profiles.plasma
  ];

  programs = {
    plasma = {
      configFile = {
        kded5rc = {
          "Module-browserintegrationflatpakintegrator" = {
            autoload = false;
          };
        };
      };

      fonts = {
        fixedWidth = fixedWidthFont;
        general = generalFont;
        menu = generalFont;

        small = generalFont // {
          pointSize = fontSize - 2;
        };

        toolbar = generalFont;
        windowTitle = generalFont;
      };

      panels = [
        {
          alignment = "center";
          floating = true;
          height = 46;
          hiding = "none";
          lengthMode = "fill";
          location = "top";
          opacity = "adaptive";

          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            {
              iconTasks = {
                launchers = [ ];
              };
            }
            "org.kde.plasma.pager"
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.colorpicker"
            {
              systemTray = {
                items = {
                  extra = [
                    "org.kde.plasma.cameraindicator"
                    "org.kde.plasma.clipboard"
                    "org.kde.plasma.devicenotifier"
                    "org.kde.plasma.manage-inputmethod"
                    "org.kde.plasma.mediacontroller"
                    "org.kde.plasma.notifications"
                    "org.kde.kscreen"
                    "org.kde.plasma.battery"
                    "org.kde.plasma.bluetooth"
                    "org.kde.plasma.brightness"
                    "org.kde.plasma.keyboardindicator"
                    "org.kde.plasma.keyboardlayout"
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.volume"
                    "org.kde.plasma.weather"
                  ];
                };
              };
            }
            {
              name = "org.kde.plasma.digitalclock";

              config = {
                Appearance = {
                  fontWeight = 400;
                };
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
    };
  };
}
