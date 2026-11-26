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

  cfg = config.programs.wemeet;
in
{
  options = {
    programs = {
      wemeet = {
        enable = mkEnableOption "A cloud-based HD conferencing product";

        package = mkPackageOption pkgs "wemeet" {
          default = "wemeet";
          nullable = true;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = optional (
        cfg.package != null
      ) cfg.package;
    };
  };
}
