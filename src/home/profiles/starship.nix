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
  home = {
    packages = with pkgs; [
      nerd-fonts.symbols-only
    ];
  };

  programs = {
    starship = {
      enable = mkDefault true;
    };
  };
}
