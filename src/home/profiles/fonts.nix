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
  fonts = {
    fontconfig = {
      antialiasing = mkDefault true;
      enable = mkDefault true;
      hinting = mkDefault "slight";
      subpixelRendering = mkDefault "none";
    };
  };
}
