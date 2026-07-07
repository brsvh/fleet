{
  home,
  pkgs,
  ...
}:
let
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

  sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
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
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';

    gtk3.extraConfig = {
      gtk-im-module = "fcitx";
    };

    gtk4.extraConfig = {
      gtk-im-module = "fcitx";
    };
  };

  home = {
    inherit
      sessionVariables
      ;
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
              "Name" = "Default";
              "Default Layout" = "us";
              "DefaultIM" = "keyboard-us";
            };

            "Groups/0/Items/0" = {
              "Name" = "rime";
              "Layout" = "";
            };

            "Groups/0/Items/1" = {
              "Name" = "keyboard-us";
              "Layout" = "";
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
