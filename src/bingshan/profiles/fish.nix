{
  home,
  ...
}:
{
  imports = [
    home.profiles.fish
  ];

  programs = {
    fish = {
      interactiveShellInit = ''
        set fish_greeting
      '';
    };
  };
}
