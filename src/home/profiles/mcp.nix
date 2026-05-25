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
    mcp = {
      enable = mkDefault true;
    };
  };
}
