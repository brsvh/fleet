{
  azaleoid,
  home,
  ...
}:
{
  imports = [
    home.profiles.gnome
    home.profiles.xdg
  ];

  dconf = {
    settings = {
      "org/gnome/desktop/session" = {
        idle-delay = 0;
      };
    };
  };

  xdg = {
    configFile = {
      "monitors.xml" = {
        source = azaleoid.etc.monitors;
      };
    };
  };
}
