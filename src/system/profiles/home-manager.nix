{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  home-manager = {
    backupFileExtension = mkDefault "home-manager-backup";
    useGlobalPkgs = mkDefault true;
    useUserPackages = mkDefault true;
  };
}
