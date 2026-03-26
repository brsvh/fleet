{
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
  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
  };
}
