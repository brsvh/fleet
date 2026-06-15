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
    bun = {
      enable = mkDefault true;
    };
  };
}
