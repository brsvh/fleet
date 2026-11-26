{
  system,
  ...
}:
{
  imports = [
    system.profiles.fail2ban
  ];

  services = {
    fail2ban = {
      bantime = "1h";

      bantime-increment = {
        enable = true;
        maxtime = "24h";
      };

      jails = {
        DEFAULT = {
          settings = {
            findtime = "10m";
          };
        };

        dovecot = {
          settings = {
            port = "993";
          };
        };

        nginx-http-auth = {
          settings = {
            port = "http,https";
          };
        };

        postfix-sasl = {
          settings = {
            port = "465";
          };
        };
      };

      maxretry = 5;
    };
  };
}
