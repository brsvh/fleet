{
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;

  cache =
    if config.home.preferXdgDirectories then
      "${config.xdg.cacheHome}/npm"
    else
      "${config.home.homeDirectory}/.npm";

  init-module =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/npm/config/npm-init.js"
    else
      "${config.home.homeDirectory}/.npm/config/npm-init.js";

  logs-dir =
    if config.home.preferXdgDirectories then
      "${config.xdg.stateHome}/npm"
    else
      "${config.home.homeDirectory}/.npm";

  prefix =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/npm"
    else
      "${config.home.homeDirectory}/.npm";
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
