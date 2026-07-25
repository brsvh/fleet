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
    displayManager = {
      plasma-login-manager = {
        enable = mkDefault true;
      };
    };
  };
}
