{
  system,
  ...
}:
let
  mkTapProfile =
    {
      gateway,
      name,
    }:
    {
      connection = {
        autoconnect = true;
        id = name;
        interface-name = name;
        type = "tun";
      };

      ipv4 = {
        address1 = "${gateway}/24";
        method = "shared";
      };

      ipv6 = {
        method = "disabled";
      };

      tun = {
        mode = 2;
        owner = 1000;
      };
    };
in
{
  imports = [
    system.profiles.network-manager
  ];

  networking = {
    firewall = {
      extraForwardRules = ''
        iifname { "tap94", "tap95" } accept
      '';
    };

    networkmanager = {
      ensureProfiles = {
        profiles = {
          tap94 = mkTapProfile {
            gateway = "192.168.94.1";
            name = "tap94";
          };

          tap95 = mkTapProfile {
            gateway = "192.168.95.1";
            name = "tap95";
          };
        };
      };
    };
  };

  users = {
    users = {
      bingshan = {
        uid = 1000;
      };
    };
  };
}
