{
  config,
  lib,
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
