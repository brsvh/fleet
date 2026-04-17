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
      choose
      cntr
      curl
      doggo
      eva
      file
      findutils
      gnugrep
      hex
      igrep
      multipath-tools
      nix-output-monitor
      nix-tree
      nixpkgs-review
      nvd
      picocom
      procs
      rnr
      tio
    ];
  };

  programs = {
    bat = {
      enable = mkDefault true;
    };

    btop = {
      enable = mkDefault true;
    };

    delta = {
      enable = mkDefault true;
    };

    eza = {
      enable = mkDefault true;
    };

    fd = {
      enable = mkDefault true;
    };

    fzf = {
      enable = mkDefault true;
    };

    jq = {
      enable = mkDefault true;
    };

    patdiff = {
      enable = mkDefault true;
    };

    ripgrep = {
      enable = mkDefault true;
    };

    screen = {
      enable = mkDefault true;
    };
  };
}
