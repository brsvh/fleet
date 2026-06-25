{
  home,
  ...
}:
{
  imports = [
    home.profiles.ollama
  ];

  services = {
    ollama = {
      models = [
        "qwen3:1.7b"
      ];
    };
  };
}
