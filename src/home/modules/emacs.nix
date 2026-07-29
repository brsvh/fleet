{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    pathExists
    types
    ;
in
{
  options = {
    programs = {
      emacs = {
        extraEarlyConfig = mkOption {
          default = "";

          description = ''
            Configuration included in the early-default library after
            the user's early init file.
          '';

          type = types.lines;
        };

        earlyInitFile = mkOption {
          default = null;

          description = ''
            The user's early init file.
          '';

          type = with types; nullOr path;
        };

        initFile = mkOption {
          default = null;

          description = ''
            The user's initialization file.
          '';

          type = with types; nullOr path;
        };
      };
    };
  };

  config =
    let
      cfg = config.programs.emacs;

      isXDG = config.xdg.enable;

      notXDG = config.xdg.enable == false;

      cond =
        v: xdg:
        cfg.enable && v != null && pathExists v && xdg;
    in
    mkMerge [
      (mkIf (cfg.enable && cfg.extraEarlyConfig != "") {
        programs = {
          emacs = {
            extraPackages = epkgs: [
              (epkgs.trivialBuild {
                pname = "early-default";
                src = pkgs.writeText "early-default.el" cfg.extraEarlyConfig;
                version = "0.1.0";
              })
            ];
          };
        };
      })
      (mkIf (cond cfg.initFile isXDG) {
        xdg = {
          configFile = {
            "emacs/init.el" = {
              source = cfg.initFile;
            };
          };
        };
      })
      (mkIf (cond cfg.earlyInitFile isXDG) {
        xdg = {
          configFile = {
            "emacs/early-init.el" = {
              source = cfg.earlyInitFile;
            };
          };
        };
      })
      (mkIf (cond cfg.initFile notXDG) {
        home = {
          file = {
            ".emacs.d/init.el" = {
              source = cfg.initFile;
            };
          };
        };
      })
      (mkIf (cond cfg.earlyInitFile notXDG) {
        home = {
          file = {
            ".emacs.d/early-init.el" = {
              source = cfg.earlyInitFile;
            };
          };
        };
      })
    ];
}
