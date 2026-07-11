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
    obs-studio = {
      enable = mkDefault true;
    };
  };
}
