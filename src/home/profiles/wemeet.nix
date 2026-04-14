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
    home.modules.wemeet
  ];

  programs = {
    wemeet = {
      enable = mkDefault true;
    };
  };
}
