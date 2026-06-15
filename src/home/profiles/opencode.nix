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
    home.profiles.git
    home.profiles.mcp
  ];

  programs = {
    git = {
      ignores = [
        "/.opencode"
      ];
    };

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
