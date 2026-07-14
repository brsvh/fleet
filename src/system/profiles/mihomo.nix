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
  services = {
    mihomo = {
      enable = mkDefault true;
      webui = pkgs.metacubexd;
    };
  };
}
