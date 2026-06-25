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
    home.modules.ollama
  ];

  services = {
    ollama = {
      acceleration = mkDefault false;
      enable = mkDefault true;
    };
  };
}
