{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (inputs)
    steam
    ;

  inherit (lib)
    mkDefault
    mkForce
    ;
in
{
  imports = [
    steam.nixosModules.default
    system.profiles.firewall
    system.profiles.gamemode
    system.profiles.gamescope
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
