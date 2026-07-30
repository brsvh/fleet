{
  config,
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.xdg
  ];

  home = {
    packages = [
      pkgs.python3Packages.grip
    ];

    sessionVariables = {
      GRIPHOME = "${config.xdg.configHome}/grip";
    };
  };
}
