{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    filterAttrs
    genAttrs
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
  config = {
    users = {
      groups =
        genAttrs
          [
            "audio"
            "cdrom"
            "dialout"
            "floppy"
            "lp"
            "systemd-journal"
            "video"
          ]
          (name: {
            members = normalUsersList;
          });
    };
  };
}
