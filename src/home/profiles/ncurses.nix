{
  config,
  home,
  ...
}:
{
  imports = [
    home.profiles.xdg
  ];

  home = {
    sessionSearchVariables = {
      TERMINFO_DIRS = [
        "${config.xdg.dataHome}/terminfo"
      ];
    };

    sessionVariables = {
      TERMINFO = "${config.xdg.dataHome}/terminfo";
    };
  };
}
