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
    git = {
      enable = mkDefault true;

      lfs = {
        enable = mkDefault true;
      };
    };
  };
}
