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
  boot = {
    loader = {
      grub = {
        enable = mkDefault true;
      };
    };
  };
}
