{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkDefault
    ;

  normalUsers = filterAttrs (
    _: v: v.enable && v.isNormalUser
  ) config.users.users;

  normalUsersList = mapAttrsToList (
    _: value: value.name
  ) normalUsers;

  storageDriver =
    if config.fileSystems."/".fsType == "btrfs" then
      "btrfs"
    else
      null;
in
{
  users = {
    groups = {
      docker = {
        members = normalUsersList;
      };
    };
  };

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
