{
  home,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    steam
    ;

  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.profiles.xdg
    steam.homeModules.default
  ];

  programs = {
    steam = {
      config = {
        enable = mkDefault true;
      };
    };
  };
}
