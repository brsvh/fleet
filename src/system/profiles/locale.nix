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
  i18n = {
    defaultCharset = mkDefault "UTF-8";
    defaultLocale = mkDefault "en_US.UTF-8";
  };
}
