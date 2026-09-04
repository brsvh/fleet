{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.tex
  ];

  programs = {
    texlive = {
      packageSet = pkgs.texliveFull;
    };
  };
}
