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
    types
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
        };
      };
    };
  };

  config = {
    home = {
      packages = mkIf (cfg.package != null) [
        cfg.package
      ];
    };
  };
}
