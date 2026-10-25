{
  bingshan,
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.xdg)
    userDirs
    ;

  inherit (lib)
    concatStringsSep
    elemAt
    getExe'
    hm
    ;

  balooExcludeFilters =
    pkgs.runCommand "baloo-exclude-filters" { }
      ''
        export XDG_CONFIG_HOME="$TMPDIR/config"
        mkdir -p "$XDG_CONFIG_HOME"

        ${getExe' pkgs.kdePackages.baloo "balooctl6"} config list excludeFilters |
          ${getExe' pkgs.gnused "sed"} -n 's/^    //p' > default-filters
        test -s default-filters
        printf '%s\n' build dist out >> default-filters
        sort -u default-filters | paste -sd, > "$out"
      '';

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
    activation = {
      balooExcludeFilters =
        hm.dag.entryAfter [ "configure-plasma" ]
          ''
            # Merge with this Baloo version's defaults instead of replacing them.
            run ${getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
              --file baloofilerc --group General --key "exclude filters" \
              "$(< ${balooExcludeFilters})"
          '';
    };

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
        baloofilerc = {
          "Basic Settings" = {
            "Indexing-Enabled" = true;
          };

          General = {
            # Explicit roots include XDG folders below .local/share.
            folders = concatStringsSep "," [
              config.home.homeDirectory
              userDirs.desktop
              userDirs.documents
              userDirs.download
              userDirs.music
              userDirs.pictures
              userDirs.publicShare
              userDirs.templates
              userDirs.videos
            ];
          };
        };

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
