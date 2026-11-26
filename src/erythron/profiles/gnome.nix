{
  erythron,
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
        monitorsFile = erythron.etc.monitors;
      };
    };
  };
}
