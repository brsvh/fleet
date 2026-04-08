{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.modules.zswap
  ];

  boot = {
    zswap = {
      acceptThresholdPercent = mkDefault 80;
      compressor = mkDefault "zstd";
      enable = mkDefault true;
      shrinkerEnabled = mkDefault true;
    };
  };
}
