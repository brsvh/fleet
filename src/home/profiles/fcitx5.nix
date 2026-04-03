{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  i18n = {
    inputMethod = {
      enable = mkDefault true;
      type = mkDefault "fcitx5";

      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          kdePackages.fcitx5-qt
          libsForQt5.fcitx5-qt
        ];

        settings = {
          addons = {
            clipboard = {
              globalSection = {
                "TriggerKey" = "";
                "PastePrimaryKey" = "";
                "Number of entries" = 5;
                "IgnorePasswordFromPasswordManager" = false;
                "ShowPassword" = false;
                "ClearPasswordAfter" = 30;
              };
            };

            notifications = {
              globalSection = {
                "HiddenNotifications" = "";
              };
            };

            quickphrase = {
              globalSection = {
                "TriggerKey" = "";
                "Choose Modifier" = "None";
                "Spell" = false;
                "FallbackSpellLanguage" = "en";
              };
            };
          };

          globalOptions = {
            "Hotkey" = {
              "EnumerateWithTriggerKeys" = true;
              "EnumerateForwardKeys" = null;
              "EnumerateBackwardKeys" = null;
              "EnumerateSkipFirst" = false;
              "ModifierOnlyKeyTimeout" = 250;
            };

            "Hotkey/TriggerKeys" = {
              "0" = "Control+Shift+Shift_L";
              "1" = "Zenkaku_Hankaku";
              "2" = "Hangul";
            };

            "Hotkey/ActivateKeys" = {
              "0" = "Hangul_Hanja";
            };

            "Hotkey/DeactivateKeys" = {
              "0" = "Hangul_Romaja";
            };

            "Hotkey/AltTriggerKeys" = {
              "0" = "Shift_L";
            };

            "Hotkey/EnumerateGroupForwardKeys" = {
              "0" = "Super+space";
            };

            "Hotkey/EnumerateGroupBackwardKeys" = {
              "0" = "Shift+Super+space";
            };

            "Hotkey/PrevPage" = {
              "0" = "Up";
            };

            "Hotkey/NextPage" = {
              "0" = "Down";
            };

            "Hotkey/PrevCandidate" = {
              "0" = "Shift+Tab";
            };

            "Hotkey/NextCandidate" = {
              "0" = "Tab";
            };

            "Hotkey/TogglePreedit" = {
              "0" = "Control+Alt+P";
            };

            "Behavior" = {
              "ActiveByDefault" = false;
              "resetStateWhenFocusIn" = "No";
              "ShareInputState" = "No";
              "PreeditEnabledByDefault" = true;
              "ShowInputMethodInformation" = true;
              "showInputMethodInformationWhenFocusIn" = false;
              "CompactInputMethodInformation" = true;
              "ShowFirstInputMethodInformation" = true;
              "DefaultPageSize" = 8;
              "OverrideXkbOption" = false;
              "CustomXkbOption" = "";
              "EnabledAddons" = "";
              "DisabledAddons" = "";
              "PreloadInputMethod" = true;
              "AllowInputMethodForPassword" = false;
              "ShowPreeditForPassword" = false;
              "AutoSavePeriod" = 30;
            };
          };
        };
      };
    };
  };
}
