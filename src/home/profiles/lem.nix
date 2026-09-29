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
    home.modules.lem
  ];

  programs = {
    lem = {
      enable = mkDefault true;
    };
  };
}
