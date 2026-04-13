{
  system,
  ...
}:
{
  imports = [
    system.profiles.openssh
  ];

  services = {
    openssh = {
      settings = {
        X11Forwarding = true;
      };
    };
  };
}
