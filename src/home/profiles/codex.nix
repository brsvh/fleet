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
    codex = {
      enable = mkDefault true;
    };

    git = {
      ignores = [
        "/.codex"
      ];
    };
  };
}
