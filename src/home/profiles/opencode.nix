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
    opencode = {
      enable = mkDefault true;
      enableMcpIntegration = mkDefault true;

      tui = {
        theme = "system";
      };

      web = {
        enable = mkDefault true;
      };
    };
  };
}
