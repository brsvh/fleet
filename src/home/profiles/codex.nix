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
    codex = {
      enable = mkDefault true;
    };
  };
}
