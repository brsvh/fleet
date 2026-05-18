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

  x509 = {
    useACMEHost = config.mailserver.fqdn;
  };
}
