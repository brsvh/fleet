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
    zswap = {
      acceptThresholdPercent = mkDefault 80;
      compressor = mkDefault "zstd";
      enable = mkDefault true;
      shrinkerEnabled = mkDefault true;
    };
  };
}
