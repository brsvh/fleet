{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  home = {
    packages = with pkgs; [
      waypipe
    ];
  };

  i18n = {
    inputMethod = {
      fcitx5 = {
        waylandFrontend = mkDefault true;
      };
    };
  };
}
