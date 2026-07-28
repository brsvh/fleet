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

  cfg = config.programs.spotify;
in
{
  options = {
    programs = {
      spotify = {
        enable = mkEnableOption "Spotify client";

        package = mkPackageOption pkgs "spotify" { };
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
