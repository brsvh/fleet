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

  inherit (pkgs)
    runCommandLocal
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

      compileElisp =
        source: file:
        runCommandLocal "emacs-${file}-byte-code" { } ''
          cp ${source} ${file}
          ${cfg.finalPackage}/bin/emacs \
            --batch \
            --quick \
            --funcall batch-byte-compile \
            ${file}
          mkdir -p $out
          cp ${file}c $out/
        '';

      compiledEarlyInitFile = compileElisp cfg.earlyInitFile "early-init.el";

      compiledInitFile = compileElisp cfg.initFile "init.el";
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

            "emacs/init.elc" = {
              source = "${compiledInitFile}/init.elc";
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

            "emacs/early-init.elc" = {
              source = "${compiledEarlyInitFile}/early-init.elc";
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

            ".emacs.d/init.elc" = {
              source = "${compiledInitFile}/init.elc";
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

            ".emacs.d/early-init.elc" = {
              source = "${compiledEarlyInitFile}/early-init.elc";
            };
          };
        };
      })
    ];
}
