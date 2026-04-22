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
  virtualisation = {
    podman = {
      enable = mkDefault true;

      defaultNetwork = {
        settings = {
          dns_enabled = true;
        };
      };
    };
  };
}
