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
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
