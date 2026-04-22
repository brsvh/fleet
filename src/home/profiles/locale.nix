{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      hunspell
      hunspellDicts.en_GB-large
      hunspellDicts.en_US-large
    ];
  };
}
