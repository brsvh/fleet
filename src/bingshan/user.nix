{
  config,
  system,
  ...
}:
{
  imports = [
    system.profiles.fish
    system.profiles.sops
  ];

  sops = {
    secrets = {
      "users/bingshan/hashed-password" = {
        neededForUsers = true;
      };
    };
  };

  users = {
    users = {
      bingshan = {
        description = "Bingshan Chang";

        extraGroups = [
          "dialout"
          "systemd-journal"
          "wheel"
        ];

        hashedPasswordFile =
          config.sops.secrets."users/bingshan/hashed-password".path;
        isNormalUser = true;

        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtKq4ewCndIVO4GnSHC14kf96lcluaMcal/gqR7/gpy openpgp:0x69F51905"
            ];
          };
        };

        shell = config.programs.fish.package;
      };
    };
  };
}
