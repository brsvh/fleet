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

  cfg = config.programs.grip;
in
{
  options = {
    programs = {
      grip = {
        enable = mkEnableOption "Grip";

        package = mkPackageOption pkgs "go-grip" { };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        cfg.package
      ];

      sessionVariables =
        mkIf (cfg.package == pkgs.python3Packages.grip)
          {
            GRIPHOME =
              if config.xdg.enable then
                "${config.xdg.configHome}/grip"
              else
                "~/.grip";
          };
    };
  };
}
