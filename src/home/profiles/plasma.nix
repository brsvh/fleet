{
  home,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs)
    plasma-manager
    ;

  inherit (lib)
    mkDefault
    ;

  inherit (pkgs)
    appmenu-gtk-module
    ;
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
    packages = [
      appmenu-gtk-module
    ];

    sessionSearchVariables = {
      GTK_PATH = [
        "${appmenu-gtk-module}/lib/gtk-2.0"
        "${appmenu-gtk-module}/lib/gtk-3.0"
      ];

      XDG_DATA_DIRS = [
        "${appmenu-gtk-module}/share/gsettings-schemas/${appmenu-gtk-module.name}"
      ];
    };

    sessionVariables = {
      GTK_MODULES = "appmenu-gtk-module";
      UBUNTU_MENUPROXY = 1;
    };
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
}
