{
  erythron,
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
        source = erythron.etc.monitors;
      };
    };
  };
}
