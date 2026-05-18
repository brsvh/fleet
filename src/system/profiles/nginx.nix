{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.profiles.acme
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        80
      ];
    };
  };

  services = {
    nginx = {
      enable = mkDefault true;
    };
  };
}
