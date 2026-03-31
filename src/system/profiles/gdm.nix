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
  services = {
    displayManager = {
      gdm = {
        enable = mkDefault true;
      };
    };
  };
}
