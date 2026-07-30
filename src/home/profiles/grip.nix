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
    home.modules.grip
    home.profiles.xdg
  ];

  programs = {
    grip = {
      enable = mkDefault true;
    };
  };
}
