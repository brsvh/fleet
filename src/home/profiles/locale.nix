{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      hunspell
      hunspellDicts.en_US-large
    ];
  };
}
