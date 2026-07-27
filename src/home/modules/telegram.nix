{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.programs.telegram;
in
{
  options = {
    programs = {
      telegram = {
        enable = mkEnableOption "Telegram Desktop";

        package =
          mkPackageOption pkgs "telegram-desktop"
            {
              default = "telegram-desktop";
            };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        cfg.package
      ];
    };
  };
}
