{
  home,
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
  imports = [
    home.profiles.ncurses
  ];

  home = {
    sessionSearchVariables = {
      TERMINFO_DIRS = [
        "${pkgs.tmux.terminfo}/share/terminfo"
      ];
    };
  };

  programs = {
    tmux = {
      enable = mkDefault true;
      terminal = mkDefault "tmux-256color";
    };
  };
}
