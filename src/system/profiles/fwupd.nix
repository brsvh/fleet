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
  services = {
    fwupd = {
      enable = mkDefault true;
    };
  };
}
