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

  cacheHome = removePrefix config.home.homeDirectory config.xdg.cacheHome;
  configHome = removePrefix config.home.homeDirectory config.xdg.configHome;
  stateHome = removePrefix config.home.homeDirectory config.xdg.stateHome;

  cache =
    if config.home.preferXdgDirectories then
      "$HOME/${cacheHome}/npm"
    else
      "$HOME/.npm";

  init-module =
    if config.home.preferXdgDirectories then
      "$HOME/${configHome}/npm/config/npm-init.js"
    else
      "$HOME/.npm/config/npm-init.js";

  logs-dir =
    if config.home.preferXdgDirectories then
      "$HOME/${stateHome}/npm"
    else
      "$HOME/.npm";

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
          cache
          init-module
          logs-dir
          prefix
          ;

        color = true;
        init-license = "MIT";
      };
    };
  };
}
