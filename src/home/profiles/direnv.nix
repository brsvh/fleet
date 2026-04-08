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
    direnv = {
      enable = mkDefault true;

      nix-direnv = {
        enable = mkDefault true;
      };
    };
  };
}
