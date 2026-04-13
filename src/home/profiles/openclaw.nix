{
  config,
  home,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    openclaw
    ;

  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.profiles.xdg
    openclaw.homeManagerModules.openclaw
  ];

  programs = {
    openclaw = {
      enable = mkDefault true;
      stateDir = "${config.xdg.stateHome}/openclaw";
    };
  };
}
