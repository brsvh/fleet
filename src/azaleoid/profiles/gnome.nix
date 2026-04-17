{
  azaleoid,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    ;

  normalUsers = filterAttrs (
    _: v: v.enable && v.isNormalUser
  ) config.users.users;
in
{
  imports = [
    system.profiles.gnome
  ];

  systemd = {
    tmpfiles = {
      rules = mapAttrsToList (
        _: v:
        "L+ ${v.home}/.config/monitors.xml - - - - ${azaleoid.etc.monitors}"
      ) normalUsers;
    };
  };
}
