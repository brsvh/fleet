{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;

  storageDriver =
    if config.fileSystems."/".fsType == "btrfs" then
      "btrfs"
    else
      null;
in
{
  virtualisation = {
    docker = {
      inherit
        storageDriver
        ;

      enable = mkDefault true;

      rootless = {
        enable = mkDefault true;
        setSocketVariable = mkDefault true;
      };
    };
  };
}
