{
  bingshan,
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    ;
in
{
  imports = [
    home.profiles.password-store
  ];

  config = mkMerge [
    (mkIf config.xdg.enable {
      programs = {
        password-store = {
          settings = {
            PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
          };
        };
      };

      xdg = {
        dataFile = {
          "password-store" = {
            recursive = true;
            source = bingshan.etc.password-store.__path;
          };
        };
      };
    })
    (mkIf (!config.xdg.enable) {
      home = {
        file = {
          ".password-store" = {
            recursive = true;
            source = bingshan.etc.password-store.__path;
          };
        };
      };

      programs = {
        password-store = {
          settings = {
            PASSWORD_STORE_DIR = "${config.home.homeDirectory}/password-store";
          };
        };
      };
    })
  ];
}
