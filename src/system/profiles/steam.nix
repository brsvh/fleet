{
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkForce
    ;
in
{
  imports = [
    system.profiles.firewall
  ];

  hardware = {
    graphics = {
      enable = mkForce true;
      enable32Bit = mkForce true;
    };
  };

  programs = {
    steam = {
      dedicatedServer = {
        openFirewall = mkDefault true;
      };

      enable = mkDefault true;

      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];

      remotePlay = {
        openFirewall = mkDefault true;
      };
    };
  };
}
