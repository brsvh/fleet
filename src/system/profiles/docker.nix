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
      enable = mkDefault false;

      rootless = {
        enable = mkDefault true;
        setSocketVariable = mkDefault true;
      };

      storageDriver = mkDefault storageDriver;
    };
  };
}
