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
    _: value: value.enable && value.isNormalUser
  ) config.users.users;

  normalUsersList = mapAttrsToList (
    _: value: value.name
  ) normalUsers;
in
{
  networking = {
    networkmanager = {
      enable = mkDefault true;
    };
  };

  users = {
    groups = {
      networkmanager = {
        members = normalUsersList;
      };
    };
  };
}
