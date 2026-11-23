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
      extraConfig = ''
        Match User archive
          ChrootDirectory /srv/archive
          DisableForwarding yes
          ForceCommand internal-sftp -d /public -u 0022 -P symlink,hardlink
          PermitTTY no
        Match all
      '';

      settings = {
        AllowUsers = [
          "archive"
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
