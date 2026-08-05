{
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.modules.inn
    home.profiles.xdg
  ];

  services = {
    inn = {
      enable = mkDefault true;
    };
  };
}
