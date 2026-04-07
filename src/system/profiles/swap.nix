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
  zramSwap = {
    algorithm = mkDefault "zstd";
    enable = mkDefault true;
    memoryPercent = mkDefault 50;
    priority = mkDefault 5;
  };
}
