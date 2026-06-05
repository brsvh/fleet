{
  azaleoid,
  system,
  ...
}:
{
  imports = [
    system.profiles.gdm
  ];

  environment = {
    etc = {
      "xdg/monitors.xml" = {
        source = azaleoid.etc.monitors;
      };
    };
  };
}
