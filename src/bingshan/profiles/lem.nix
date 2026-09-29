{
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.profiles.lem
  ];

  programs = {
    lem = {
      package = mkDefault pkgs.lem-webview;
    };
  };
}
