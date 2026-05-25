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
    claude-code = {
      enable = mkDefault true;
      enableMcpIntegration = mkDefault true;
    };
  };
}
