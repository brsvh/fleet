{
  config,
  home,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  inherit (lib)
    head
    optionalAttrs
    optionalString
    splitString
    ;

  xkb =
    if osConfig != null then
      osConfig.services.xserver.xkb
    else
      {
        layout = "us";
        variant = "";
      };

  layout = head (splitString "," xkb.layout);
  variant = head (splitString "," xkb.variant);

  keyboardLayout =
    layout
    + optionalString (variant != "") "-${variant}";

  keyboardInputMethod = "keyboard-${keyboardLayout}";

  toYAML =
    name: attrs:
    (pkgs.formats.yaml { }).generate name attrs;

  rimeDefaultConfig = toYAML "default.custom.yaml" {
    "patch" = {
      "__include" = "rime_frost_suggestion:/";

      "schema_list" = [
        {
          "schema" = "rime_frost";
        }
      ];
    };
  };

  rimeFrostConfig =
    toYAML "rime_frost.custom.yaml"
      {
        "patch" = {
          "grammar" = {
            "collocation_max_length" = 5;
            "collocation_min_length" = 2;
            "collocation_penalty" = -14;
            "language" = "zh-moqi";
            "non_collocation_penalty" = -4;
          };

          "switches/@4/reset" = 1;
          "translator/contextual_suggestions" = true;
          "translator/max_homographs" = 2;
          "translator/max_homophones" = 4;
        };
      };

  nativeFcitx5 =
    (config.programs.plasma.enable or false)
    && config.i18n.inputMethod.fcitx5.waylandFrontend;

  sessionVariables = {
    XMODIFIERS = "@im=fcitx";
  }
  // optionalAttrs nativeFcitx5 {
    QT_IM_MODULES = "wayland;fcitx;ibus";
  }
  // optionalAttrs (!nativeFcitx5) {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
in
{
  imports = [
    home.profiles.fcitx5
    home.profiles.gtk
    home.profiles.xdg
  ];

  gtk = {
    gtk2 = {
      extraConfig = ''
        gtk-im-module="fcitx"
      '';
    };

    gtk3 = {
      extraConfig = {
        gtk-im-module = "fcitx";
      };
    };

    gtk4 = {
      extraConfig = {
        gtk-im-module = "fcitx";
      };
    };
  };

  i18n = {
    inputMethod = {
      fcitx5 = {
        addons = with pkgs; [
          (fcitx5-rime.override {
            librime = librime.override {
              plugins = [
                librime-lua
                librime-octagram
              ];
            };

            rimeDataPkgs = [
              rime-frost
            ];
          })
        ];

        sessionVariables = sessionVariables // {
          GLFW_IM_MODULE = "ibus";
        };

        settings = {
          addons = {
            rime = {
              globalSection = {
                "PreeditMode" = "No";
              };
            };
          };

          inputMethod = {
            GroupOrder = {
              "0" = "Default";
            };

            "Groups/0" = {
              "Default Layout" = keyboardLayout;
              "DefaultIM" = keyboardInputMethod;
              "Name" = "Default";
            };

            "Groups/0/Items/0" = {
              "Layout" = "";
              "Name" = "rime";
            };

            "Groups/0/Items/1" = {
              "Layout" = "";
              "Name" = keyboardInputMethod;
            };
          };
        };
      };
    };
  };

  systemd = {
    user = {
      inherit
        sessionVariables
        ;
    };
  };

  xdg = {
    dataFile = {
      "fcitx5/rime/default.custom.yaml" = {
        source = rimeDefaultConfig;
      };

      "fcitx5/rime/rime_frost.custom.yaml" = {
        source = rimeFrostConfig;
      };
    };
  };
}
