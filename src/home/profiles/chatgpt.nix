{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      llm-agents.chatgpt
    ];
  };
}
