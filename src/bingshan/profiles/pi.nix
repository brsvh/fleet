{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.pi
  ];

  programs = {
    pi-coding-agent = {
      package = pkgs.llm-agents.pi;
    };
  };
}
