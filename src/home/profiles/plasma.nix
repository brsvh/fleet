{
  home,
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  inherit (inputs)
    plasma-manager
    ;

  inherit (lib)
    elemAt
    genList
    getExe
    length
    mkDefault
    mkIf
    splitString
    ;

  xkb = osConfig.services.xserver.xkb;
  layouts = splitString "," xkb.layout;
  variants = splitString "," xkb.variant;
in
{
  imports = [
    home.profiles.gtk
    home.profiles.qt
    plasma-manager.homeModules.plasma-manager
  ];

  gtk = {
    colorScheme = mkDefault "light";

    cursorTheme = {
      name = mkDefault "breeze_cursors";
      package = mkDefault pkgs.kdePackages.breeze;
    };

    iconTheme = {
      name = mkDefault "breeze";
      package = mkDefault pkgs.kdePackages.breeze-icons;
    };

    theme = {
      name = mkDefault "Breeze";
      package = mkDefault pkgs.kdePackages.breeze-gtk;
    };
  };

  home = {
    packages = with pkgs; [
      haruna
      plasma-plugin-waywallen
      waywallen
    ];
  };

  i18n = {
    inputMethod = {
      fcitx5 = {
        settings = {
          addons = {
            classicui = {
              globalSection = {
                "Theme" = mkDefault "plasma";
              };
            };
          };
        };
      };
    };
  };

  programs = {
    plasma = {
      enable = mkDefault true;

      input = {
        keyboard = mkIf (osConfig != null) {
          layouts = genList (index: {
            layout = elemAt layouts index;

            variant =
              if index < length variants then
                elemAt variants index
              else
                "";
          }) (length layouts);

          model = xkb.model;
          options = splitString "," xkb.options;
        };
      };

      workspace = {
        colorScheme = mkDefault "BreezeLight";

        cursor = {
          theme = mkDefault "breeze_cursors";
        };

        iconTheme = mkDefault "breeze";
        theme = mkDefault "default";
      };
    };
  };

  qt = {
    platformTheme = {
      name = mkDefault "kde";
    };

    style = {
      name = mkDefault "breeze";
    };
  };

  services = {
    gpg-agent = {
      pinentry = {
        package = pkgs.pinentry-qt;
        program = "pinentry-qt";
      };
    };
  };

  systemd = {
    user = {
      services = {
        gpg-agent = {
          Service = {
            Environment = [
              "PINENTRY_KDE_USE_WALLET=1"
            ];
          };
        };

        waywallen = {
          Install = {
            WantedBy = [
              "graphical-session.target"
            ];
          };

          Service = {
            ExecStart = "${getExe pkgs.waywallen} --no-ui";
            Restart = "on-failure";
          };

          Unit = {
            After = [
              "graphical-session.target"
            ];

            Description = "Waywallen wallpaper manager";

            PartOf = [
              "graphical-session.target"
            ];
          };
        };
      };
    };
  };
}
