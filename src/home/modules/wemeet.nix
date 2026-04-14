{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    types
    ;
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
}
