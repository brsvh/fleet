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
  programs = {
    fish = {
      enable = mkDefault true;
    };
  };
}
