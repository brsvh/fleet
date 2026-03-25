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
    guix = {
      enable = mkDefault true;
    };
  };
}
