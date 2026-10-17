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
        AllowUsers = [
          "ops"
          "root"
        ];

        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        LoginGraceTime = 30;
        MaxAuthTries = 3;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
