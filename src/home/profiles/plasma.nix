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
