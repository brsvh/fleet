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
      enable = true;
      enableWsi = mkDefault true;
    };
  };
}
