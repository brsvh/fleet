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
    };
  };
}
