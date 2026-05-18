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
  security = {
    acme = {
      acceptTerms = mkDefault true;
    };
  };
}
