{
  bingshan,
  config,
  home,
  lib,
  pkgs,
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

  monospace = {
    family = first fontFamilies.monospace;
    pointSize = fontSize;
  };

  sansSerif = {
    family = first fontFamilies.sansSerif;
    pointSize = fontSize;
  };

  waywallen = {
    plugin = "org.waywallen.kde";
  };
in
{
  imports = [
    bingshan.profiles.fonts
    bingshan.profiles.gtk
    bingshan.profiles.xdg
    home.profiles.plasma
  ];

  home = {
    packages =
      (with pkgs; [
        subtitlecomposer
      ])
      ++ (with pkgs.kdePackages; [
        kdenlive
      ]);

    sessionVariables = {
      PULSE_COOKIE = "${config.xdg.configHome}/pulse/cookie";
    };
  };

  programs = {
    plasma = {
      configFile = {
        kded6rc = {
          "Module-browserintegrationflatpakintegrator" = {
            autoload = false;
          };

          "Module-browserintegrationreminder" = {
            autoload = false;
          };
        };
      };

      fonts = {
        fixedWidth = monospace;
        general = sansSerif;
        menu = sansSerif;

        small = sansSerif // {
          pointSize = fontSize - 2;
        };

        toolbar = sansSerif;
        windowTitle = sansSerif;
      };

      kscreenlocker = {
        appearance = {
          wallpaperCustomPlugin = waywallen;
        };
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

      workspace = {
        wallpaperCustomPlugin = waywallen;
      };
    };
  };
}
