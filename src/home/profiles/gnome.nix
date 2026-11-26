{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    map
    mkDefault
    ;
in
{
  imports = [
    home.profiles.gtk
    home.profiles.qt
  ];

  dconf = {
    settings = {
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
        edge-tiling = true;

        experimental-features = [
          "scale-monitor-framebuffer"
          "xwayland-native-scaling"
        ];
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = map (
          extension:
          if extension ? id then
            extension.id
          else
            extension.extensionUuid
        ) config.programs.gnome-shell.extensions;
      };

      "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
      };
    };
  };

  gtk = {
    cursorTheme = {
      name = mkDefault "Adwaita";
      package = mkDefault pkgs.adwaita-icon-theme;
    };

    iconTheme = {
      name = mkDefault "Adwaita";
      package = mkDefault pkgs.adwaita-icon-theme;
    };
  };

  programs = {
    gnome-shell = {
      extensions = with pkgs.gnomeExtensions; [
        {
          id = "add-username-toppanel@brendaw.com";
          package = add-username-to-top-panel;
        }
        {
          id = "appindicatorsupport@rgcjonas.gmail.com";
          package = appindicator;
        }
        {
          id = "kimpanel@kde.org";
          package = kimpanel;
        }
        {
          id = "user-theme@gnome-shell-extensions.gcampax.github.com";
          package = user-themes;
        }
      ];
    };
  };

  qt = {
    platformTheme = {
      name = mkDefault "adwaita";
    };

    style = {
      name = mkDefault "adwaita";
    };
  };

  services = {
    gpg-agent = {
      pinentry = {
        package = pkgs.pinentry-gnome3;
        program = "pinentry-gnome3";
      };
    };
  };
}
