{
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.profiles.mcp
  ];

  programs = {
    codex = {
      enable = mkDefault true;
    };
  };
}
