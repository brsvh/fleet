{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  boot = {
    enableContainers = mkDefault true;
  };

  virtualisation = {
    containers = {
      enable = mkDefault true;
    };
  };
}
