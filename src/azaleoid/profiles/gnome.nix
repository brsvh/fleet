{
  azaleoid,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    concatLists
    filterAttrs
    mapAttrsToList
    pipe
    ;

  normalUsers = filterAttrs (
    _: value: value.enable && value.isNormalUser
  ) config.users.users;

  userGroup =
    user:
    let
      group = config.users.users.${user}.group;
    in
    if group == null || group == "" then
      "users"
    else
      group;
in
{
  imports = [
    system.profiles.gnome
  ];

  systemd = {
    tmpfiles = {
      rules = pipe normalUsers [
        (mapAttrsToList (
          name: value: [
            "d ${value.home}/.config 0700 ${value.name} ${userGroup name} -"
            "L+ ${value.home}/.config/monitors.xml - - - - ${azaleoid.etc.monitors}"
          ]
        ))
        concatLists
      ];
    };
  };
}
