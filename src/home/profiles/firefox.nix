{
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.profiles.xdg
  ];

  programs = {
    firefox = {
      enable = mkDefault true;
    };
  };
}
