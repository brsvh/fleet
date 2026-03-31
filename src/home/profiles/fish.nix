{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  home = {
    shell = {
      enableFishIntegration = mkDefault true;
    };
  };

  programs = {
    fish = {
      enable = mkDefault true;
    };
  };
}
