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
  networking = {
    networkmanager = {
      enable = mkDefault true;
    };
  };
}
