{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatLists
    filterAttrs
    mapAttrsToList
    mkIf
    mkOption
    pipe
    types
    ;

  cfg = config.services.desktopManager.gnome;

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
  options = {
    services = {
      desktopManager = {
        gnome = {
          monitorsFile = mkOption {
            default = null;

            description = ''
              Path to a monitors.xml file linked into each normal user's
              ~/.config/monitors.xml via systemd tmpfiles.
            '';

            type = types.nullOr types.path;
          };
        };
      };
    };
  };

  config =
    mkIf (cfg.enable && cfg.monitorsFile != null)
      {
        systemd = {
          tmpfiles = {
            rules = pipe normalUsers [
              (mapAttrsToList (
                name: value: [
                  "d ${value.home}/.config 0700 ${value.name} ${userGroup name} -"
                  "L+ ${value.home}/.config/monitors.xml - - - - ${cfg.monitorsFile}"
                ]
              ))
              concatLists
            ];
          };
        };
      };
}
