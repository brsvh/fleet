{
  home,
  ...
}:
{
  imports = [
    home.profiles.gnome
  ];

  dconf = {
    settings = {
      "org/gnome/desktop/session" = {
        idle-delay = 0;
      };
    };
  };
}
