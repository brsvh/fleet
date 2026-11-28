{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      bubblewrap
      llm-agents.chatgpt
    ];
  };
}
