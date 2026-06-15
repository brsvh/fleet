{
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    removePrefix
    ;

  configHome = removePrefix config.home.homeDirectory config.xdg.configHome;

  prefix =
    if config.home.preferXdgDirectories then
      "$HOME/${configHome}/npm"
    else
      "$HOME/.npm";
in
{
  imports = [
    home.profiles.xdg
  ];

  programs = {
    npm = {
      enable = mkDefault true;

      settings = {
        inherit
          prefix
          ;

        color = true;
        init-license = "MIT";
      };
    };
  };
}
