{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.codex
  ];

  programs = {
    codex = {
      package = pkgs.llm-agents.codex;
    };
  };
}
