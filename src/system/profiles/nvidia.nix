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
  hardware = {
    nvidia = {
      modesetting = {
        enable = mkDefault true;
      };

      open = mkDefault true;

      powerManagement = {
        enable = mkDefault true;
        finegrained = mkDefault false;
      };
    };
  };

  services = {
    xserver = {
      videoDrivers = mkDefault [
        "nvidia"
      ];
    };
  };
}
