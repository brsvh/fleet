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
  programs = {
    dconf = {
      enable = mkDefault true;
    };
  };
}
