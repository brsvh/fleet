{
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkForce
    ;
in
{
  imports = [
    system.profiles.dconf
    system.profiles.qt
    system.profiles.wayland
  ];

  environment = {
    systemPackages = with pkgs.gnomeExtensions; [
      appindicator
      kimpanel
    ];
  };

  programs = {
    dconf = {
      profiles = {
        gnome = {
          databases = [
            {
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
                  enabled-extensions = [
                    "appindicatorsupport@rgcjonas.gmail.com"
                    "kimpanel@kde.org"
                    "user-theme@gnome-shell-extensions.gcampax.github.com"
                    p
                  ];
                };
              };
            }
          ];
        };
      };
    };
  };

  qt = {
    platformTheme = mkForce "gnome";
    style = mkForce "adwaita";
  };

  services = {
    desktopManager = {
      gnome = {
        enable = mkDefault true;
      };
    };

    gnome = {
      gnome-initial-setup = {
        enable = mkForce false;
      };
    };
  };
}
