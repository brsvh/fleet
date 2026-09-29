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

  cfg = config.programs.lem;
in
{
  options = {
    programs = {
      lem = {
        enable = mkEnableOption "Lem editor";

        package = mkPackageOption pkgs "lem-ncurses" { };
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
