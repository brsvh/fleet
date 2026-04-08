{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    mkIf
    mkMerge
    types
    ;
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

  config =
    let
      cfg = config.programs.global;

      isXDG = config.xdg.enable;

      notXDG = !isXDG;

      cond = xdg: cfg.enable && xdg;
    in
    mkMerge [
      {
        home = {
          packages = with pkgs; [
            cfg.ctags
            cfg.package
            python3
            python3Packages.pygments
          ];
        };
      }
      (mkIf (cond isXDG) {
        home = {
          sessionVariables = {
            GTAGSOBJDIRPREFIX =
              config.xdg.cacheHome + "/gtags";
          };
        };
      })
      (mkIf (cond notXDG) {
        home = {
          sessionVariables = {
            GTAGSOBJDIRPREFIX = "~/.cache/gtags/";
          };
        };
      })
    ];
}
