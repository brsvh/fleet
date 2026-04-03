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
  qt = {
    enable = mkDefault true;
  };
}
