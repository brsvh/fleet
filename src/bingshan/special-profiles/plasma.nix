{
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkForce
    ;
in
{
  imports = [
    home.profiles.plasma
  ];

  programs = {
    emacs = {
      package = mkForce (
        pkgs.emacs-git.override {
          withGTK3 = true;
          withPgtk = false;
        }
      );
    };

    plasma = {
      panels = [
        {
          alignment = "center";
          floating = true;
          height = 46;
          hiding = "none";
          lengthMode = "fill";
          location = "top";
          opacity = "adaptive";
          screen = 0;

          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            {
              iconTasks = {
                launchers = [
                  "preferred://browser"
                ];
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
