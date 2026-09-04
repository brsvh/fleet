{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  programs = {
    texlive = {
      enable = mkDefault true;
      packageSet = mkDefault pkgs.texliveSmall;
    };
  };
}
