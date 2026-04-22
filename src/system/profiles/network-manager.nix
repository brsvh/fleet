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
in
{
  networking = {
    networkmanager = {
      enable = mkDefault true;
    };
  };

  users = {
    groups = {
      network-manager = {
        members = normalUsersList;
      };
    };
  };
}
