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
    knot-resolver = {
      enable = mkDefault true;
    };
  };
}
