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
    harmonia = {
      cache = {
        enable = mkDefault true;

        settings = {
          bind = mkDefault "127.0.0.1:5000";
        };
      };
    };
  };
}
