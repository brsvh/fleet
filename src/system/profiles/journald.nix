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
  services = {
    journald = {
      settings = {
        Journal = {
          Compress = mkDefault true;
          MaxFileSec = mkDefault "1day";
        };
      };
    };
  };
}
