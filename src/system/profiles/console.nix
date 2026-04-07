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
  console = {
    earlySetup = mkDefault true;

    font = mkDefault "${pkgs.kbd}/share/consolefonts/eurlatgr.psfu.gz";
  };
}
