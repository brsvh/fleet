{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.opencode
  ];

  programs = {
    opencode = {
      package = pkgs.llm-agents.opencode;
    };
  };
}
