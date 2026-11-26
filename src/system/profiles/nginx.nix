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

  services = {
    nginx = {
      enable = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;
      recommendedTlsSettings = mkDefault true;
    };
  };
}
