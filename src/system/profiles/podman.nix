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
      defaultNetwork = {
        settings = {
          dns_enabled = true;
        };
      };

      enable = mkDefault true;
    };
  };
}
