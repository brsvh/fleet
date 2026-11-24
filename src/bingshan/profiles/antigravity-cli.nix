{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.antigravity-cli
  ];

  programs = {
    antigravity-cli = {
      package = pkgs.llm-agents.antigravity-cli;
    };
  };
}
