{
  config,
  erythron,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    concatLists
    filterAttrs
    hasPrefix
    mapAttrsToList
    ;

  greeterUsers = filterAttrs (
    name: user:
    user.enable && hasPrefix "gdm-greeter" name
  ) config.users.users;
in
{
  imports = [
    system.profiles.gdm
  ];

  systemd = {
    tmpfiles = {
      rules = concatLists (
        mapAttrsToList (name: user: [
          "d ${user.home}/.config 0711 ${name} gdm"
          "L+ ${user.home}/.config/monitors.xml - - - - ${erythron.etc.monitors}"
        ]) greeterUsers
      );
    };
  };
}
