{
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    ;
in
{
  imports = [
    home.modules.antigravity-cli
    home.profiles.git
    home.profiles.mcp
    home.profiles.xdg
  ];

  programs = {
    antigravity-cli = {
      enable = mkDefault true;
      enableMcpIntegration = mkDefault true;

      geminiDir = mkIf config.home.preferXdgDirectories (
        mkDefault "${config.xdg.dataHome}/antigravity"
      );

      mutableSettings = mkDefault true;
    };

    git = {
      ignores = [
        "/.gemini"
      ];
    };
  };
}
