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
    optional
    ;

  cfg = config.programs.global;
in
{
  options = {
    programs = {
      global = {
        ctags = mkPackageOption pkgs "universal-ctags" {
          example = "pkgs.universal-ctags";
          nullable = true;
        };

        enable = mkEnableOption "Global";

        package = mkPackageOption pkgs "global" {
          example = "pkgs.global";
          nullable = true;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        optional (cfg.ctags != null) cfg.ctags
        ++ optional (cfg.package != null) cfg.package
        ++ (with pkgs; [
          python3
          python3Packages.pygments
        ]);

      sessionVariables = {
        GTAGSOBJDIRPREFIX =
          if config.xdg.enable then
            "${config.xdg.cacheHome}/gtags"
          else
            "${config.home.homeDirectory}/.cache/gtags";
      };
    };
  };
}
