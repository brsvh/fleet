{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  environment = {
    systemPackages = with pkgs; [
      OVMFFull
    ];
  };

  virtualisation = {
    libvirtd = {
      enable = mkDefault true;
    };
  };
}
