{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  home-manager = {
    # Preserve older backups when applications rewrite managed files.
    backupCommand = mkDefault (
      pkgs.writeShellScript "home-manager-backup" ''
        exec ${pkgs.coreutils}/bin/mv \
          --backup=numbered \
          --no-target-directory \
          -- "$1" "$1.home-manager-backup"
      ''
    );

    useGlobalPkgs = mkDefault true;
    useUserPackages = mkDefault true;
  };
}
