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
    enable = mkDefault true;
    enableMcpIntegration = mkDefault true;
  };
}
