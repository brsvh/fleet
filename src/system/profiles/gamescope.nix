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
      # Override NixOS steam.nix's mkDefault false when gamescopeSession is off.
      enable = true;
      enableWsi = mkDefault true;
    };
  };
}
