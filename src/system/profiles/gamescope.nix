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
    gamescope = {
      enable = mkDefault true;
      enableWsi = mkDefault true;
    };
  };
}
