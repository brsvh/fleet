{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    ;

  toYAML =
    name: attrs:
    (pkgs.formats.yaml { }).generate name attrs;

  rimeConfig = toYAML "default.custom.yaml" {
    "patch" = {
      "__include" = "rime_ice_suggestion:/";

      "schema_list" = [
        {
          "schema" = "rime_ice";
        }
      ];
    };
  };
in
{
  imports = [
    home.profiles.fcitx5
    home.profiles.xdg
  ];

  i18n = {
    inputMethod = {
      fcitx5 = {
        addons = with pkgs; [
          (fcitx5-rime.override {
            rimeDataPkgs = [
              rime-ice
            ];
          })
        ];

        settings = {
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

  xdg = {
    dataFile = {
      "fcitx5/rime/default.custom.yaml" = {
        source = rimeConfig;
      };
    };
  };
}
