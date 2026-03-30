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
    plymouth = {
      enable = mkDefault true;
      theme = mkDefault "bgrt";
    };
  };
}
