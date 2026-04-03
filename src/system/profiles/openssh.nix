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
    openssh = {
      enable = mkDefault true;
    };
  };
}
