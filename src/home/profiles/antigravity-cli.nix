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
    antigravity-cli = {
      enable = mkDefault true;
      enableMcpIntegration = mkDefault true;
      mutableSettings = mkDefault true;
    };

    git = {
      ignores = [
        "/.gemini"
      ];
    };
  };
}
