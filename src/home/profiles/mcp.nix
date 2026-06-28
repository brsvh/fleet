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
      socat
    ];
  };

  programs = {
    mcp = {
      enable = mkDefault true;
    };
  };
}
