{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  services = {
    openssh = {
      enable = mkDefault true;

      settings = {
        AuthenticationMethods = mkDefault "publickey";
        KbdInteractiveAuthentication = mkDefault false;
        LoginGraceTime = mkDefault 30;
        MaxAuthTries = mkDefault 3;
        PasswordAuthentication = mkDefault false;
        PermitRootLogin = mkDefault "prohibit-password";
      };
    };
  };
}
