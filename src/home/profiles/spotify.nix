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
    home.modules.spotify
  ];

  programs = {
    spotify = {
      enable = mkDefault true;
    };
  };
}
