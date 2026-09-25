{
  system,
  ...
}:
{
  imports = [
    system.profiles.journald
  ];

  services = {
    journald = {
      settings = {
        Journal = {
          MaxRetentionSec = "28day";
          RuntimeMaxUse = "128M";
          SystemKeepFree = "5G";
          SystemMaxFileSize = "64M";
          SystemMaxUse = "1G";
        };
      };
    };
  };
}
