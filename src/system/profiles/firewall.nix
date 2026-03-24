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
    firewall = {
      enable = mkDefault true;
    };

    nftables = {
      enable = mkDefault true;
    };
  };
}
