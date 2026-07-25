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
    harmonia = {
      cache = {
        enable = mkDefault true;
      };
    };
  };
}
