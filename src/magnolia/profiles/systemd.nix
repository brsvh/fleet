{
  system,
  ...
}:
{
  imports = [
    system.profiles.systemd
  ];

  systemd = {
    sleep = {
      settings = {
        Sleep = {
          AllowHibernation = "yes";
        };
      };
    };
  };
}
