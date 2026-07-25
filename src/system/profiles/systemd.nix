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
  boot = {
    initrd = {
      systemd = {
        enable = mkDefault true;
      };
    };
  };
}
