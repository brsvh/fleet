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
    home.modules.telegram
  ];

  programs = {
    telegram = {
      enable = mkDefault true;
    };
  };
}
