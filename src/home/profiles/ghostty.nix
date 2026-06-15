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
    ghostty = {
      enable = mkDefault true;
    };
  };
}
