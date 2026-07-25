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
  security = {
    rtkit = {
      enable = mkDefault true;
    };
  };

  services = {
    pipewire = {
      alsa = {
        enable = mkDefault true;
      };

      audio = {
        enable = mkDefault true;
      };

      enable = mkDefault true;

      pulse = {
        enable = mkDefault true;
      };

      wireplumber = {
        enable = mkDefault true;
      };
    };
  };
}
