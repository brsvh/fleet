{
  home,
  ...
}:
{
  imports = [
    home.profiles.fish
    home.profiles.starship
  ];

  programs = {
    fish = {
      interactiveShellInit = ''
        set fish_greeting
      '';
    };

    starship = {
      presets = [
        "jetpack"
      ];
    };
  };
}
