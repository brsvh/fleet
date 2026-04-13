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
      allowBitmaps = mkDefault false;
      allowType1 = mkDefault false;
      cache32Bit = mkDefault false;

      enable = mkDefault true;

      hinting = {
        autohint = mkDefault false;
        enable = mkDefault true;
        style = "slight";
      };

      includeUserConf = mkDefault true;

      subpixel = {
        lcdfilter = mkDefault "none";
        rgba = mkDefault "none";
      };

      useEmbeddedBitmaps = mkDefault false;
    };
  };
}
