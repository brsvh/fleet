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
      comma
      nix-du
      nix-prefetch-scripts
      nix-tree
    ];
  };

  programs = {
    nh = {
      clean = {
        dates = "monthly";
      };

      enable = mkDefault true;
    };

    nix-index = {
      enable = mkDefault true;
    };

    nix-init = {
      enable = mkDefault true;
    };
  };
}
