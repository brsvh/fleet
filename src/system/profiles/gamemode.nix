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
    gamemode = {
      enable = mkDefault true;
    };
  };
}
