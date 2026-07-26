{
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    getExe
    ;

  inherit (pkgs)
    liquidctl
    ;
in
{
  imports = [
    system.profiles.liquidctl
  ];

  systemd = {
    services = {
      liquidctl-color = {
        after = [
          "systemd-udev-settle.service"
        ];

        description = "Configure liquidctl device colors";

        serviceConfig = {
          ExecStart = "${getExe liquidctl} --vendor 0b05 --product 19af set sync color static ff0000";
          RemainAfterExit = true;
          Type = "oneshot";
        };

        wantedBy = [
          "multi-user.target"
        ];

        wants = [
          "systemd-udev-settle.service"
        ];
      };
    };
  };
}
