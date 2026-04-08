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
    chromium = {
      enable = mkDefault true;
      package = mkDefault pkgs.google-chrome;
    };
  };
}
