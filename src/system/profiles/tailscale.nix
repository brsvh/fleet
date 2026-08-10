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
    tailscale = {
      disableUpstreamLogging = mkDefault true;
      enable = mkDefault true;
      openFirewall = mkDefault true;
      useRoutingFeatures = mkDefault "none";
    };
  };
}
