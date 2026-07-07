{
  config,
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
    cargo = {
      cargoHome = mkDefault "${config.xdg.dataHome}/cargo";
      enable = mkDefault true;
    };
  };
}
