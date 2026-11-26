{
  azaleoid,
  system,
  ...
}:
{
  imports = [
    system.profiles.gnome
  ];

  services = {
    desktopManager = {
      gnome = {
        monitorsFile = azaleoid.etc.monitors;
      };
    };
  };
}
