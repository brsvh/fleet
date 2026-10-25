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
                "ClearPasswordAfter" = 30;
                "IgnorePasswordFromPasswordManager" = false;
                "Number of entries" = 5;
                "PastePrimaryKey" = "";
                "ShowPassword" = false;
                "TriggerKey" = "";
              };
            };

            notifications = {
              globalSection = {
                "HiddenNotifications" = "";
              };
            };

            quickphrase = {
              globalSection = {
                "Choose Modifier" = "None";
                "FallbackSpellLanguage" = "en";
                "Spell" = false;
                "TriggerKey" = "";
              };
            };
          };

          globalOptions = {
            "Behavior" = {
              "ActiveByDefault" = false;
              "AllowInputMethodForPassword" = false;
              "AutoSavePeriod" = 30;
              "CompactInputMethodInformation" = true;
              "CustomXkbOption" = "";
              "DefaultPageSize" = 8;
              "DisabledAddons" = "";
              "EnabledAddons" = "";
              "OverrideXkbOption" = false;
              "PreeditEnabledByDefault" = false;
              "PreloadInputMethod" = true;
              "ShareInputState" = "No";
              "ShowFirstInputMethodInformation" = true;
              "ShowInputMethodInformation" = true;
              "ShowPreeditForPassword" = false;
              "resetStateWhenFocusIn" = "No";
              "showInputMethodInformationWhenFocusIn" = false;
            };

            "Hotkey" = {
              "EnumerateBackwardKeys" = null;
              "EnumerateForwardKeys" = null;
              "EnumerateSkipFirst" = false;
              "EnumerateWithTriggerKeys" = true;
              "ModifierOnlyKeyTimeout" = 250;
            };

            "Hotkey/ActivateKeys" = {
              "0" = "Hangul_Hanja";
            };

            "Hotkey/AltTriggerKeys" = {
              "0" = "Shift_L";
            };

            "Hotkey/DeactivateKeys" = {
              "0" = "Hangul_Romaja";
            };

            "Hotkey/EnumerateGroupBackwardKeys" = {
              "0" = "Shift+Super+space";
            };

            "Hotkey/EnumerateGroupForwardKeys" = {
              "0" = "Super+space";
            };

            "Hotkey/NextCandidate" = {
              "0" = "Tab";
            };

            "Hotkey/NextPage" = {
              "0" = "Down";
            };

            "Hotkey/PrevCandidate" = {
              "0" = "Shift+Tab";
            };

            "Hotkey/PrevPage" = {
              "0" = "Up";
            };

            "Hotkey/TogglePreedit" = {
              "0" = "Control+Alt+P";
            };

            "Hotkey/TriggerKeys" = {
              "0" = "Control+Shift+Shift_L";
              "1" = "Zenkaku_Hankaku";
              "2" = "Hangul";
            };
          };
        };
      };

      type = mkDefault "fcitx5";
    };
  };
}
