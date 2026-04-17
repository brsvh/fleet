{
  erythron,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    concatLists
    concatStringsSep
    escapeShellArg
    filterAttrs
    mapAttrsToList
    ;

  normalUsers = filterAttrs (
    _: v: v.enable && v.isNormalUser
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
      rules = concatLists (
        mapAttrsToList (n: v: [
          "d ${v.home}/.config 0700 ${v.name} ${userGroup n} -"
          "L+ ${v.home}/.config/monitors.xml - - - - ${erythron.etc.monitors}"
        ]) normalUsers
      );
    };
  };

  system = {
    activationScripts = {
      userMonitorsPermission = {
        text = concatStringsSep "\n" (
          mapAttrsToList (n: v: ''
            cfg=${v.home}/.config

            if [ -L "$cfg" ]; then
              :
            elif [ -d "$cfg" ]; then
              chown ${v.name}:${userGroup n} "$cfg"
              chmod 0700 "$cfg"
            else
              install -d -m 0700 -o ${v.name} -g ${userGroup n} "$cfg"
            fi

            rm -rf "$cfg/monitors.xml"
            ln -s ${erythron.etc.monitors} "$cfg/monitors.xml"

            chown -h ${v.name}:${userGroup n} "$cfg/monitors.xml"
          '') normalUsers
        );
      };
    };
  };

}
