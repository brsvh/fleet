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
    fail2ban = {
      enable = mkDefault true;
    };
  };
}
