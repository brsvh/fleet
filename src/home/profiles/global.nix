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
    home.modules.global
  ];

  programs = {
    global = {
      enable = mkDefault true;
    };
  };
}
