{
  azaleoid,
  system,
  ...
}:
{
  imports = [
    system.profiles.gdm
  ];

  systemd = {
    tmpfiles = {
      rules =
        let
          inherit (config.users.users.gdm)
            home
            ;
        in
        [
          "d ${home}/.config 0711 gdm gdm"
          "L+ ${home}/.config/monitors.xml - - - - ${azaleoid.etc.monitors}"
        ];
    };
  };
}
