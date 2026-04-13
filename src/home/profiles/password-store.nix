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
    password-store = {
      enable = mkDefault true;
    };
  };
}
