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
  networking = {
    dhcpcd = {
      enable = mkDefault true;
      IPv6rs = mkDefault true;
      persistent = mkDefault true;
    };

    useDHCP = mkDefault true;
  };
}
