{
  config,
  inputs,
  lib,
  system,
  ...
}:
let
  inherit (inputs)
    mailserver
    ;

  inherit (lib)
    mkDefault
    ;

  cfg = config.mailserver;
in
{
  imports = [
    mailserver.nixosModules.default
    system.profiles.nginx
  ];

  mailserver = {
    enable = mkDefault true;
    stateVersion = mkDefault 4;

    x509 = {
      useACMEHost = cfg.fqdn;
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "${cfg.fqdn}" = {
          enableACME = mkDefault true;
        };
      };
    };
  };
}
