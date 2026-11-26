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
      "users/root/hashed-password" = {
        neededForUsers = true;
      };
    };
  };

  users = {
    users = {
      root = {
        hashedPasswordFile =
          config.sops.secrets."users/root/hashed-password".path;

        openssh = {
          authorizedKeys = {
            keys = [
              "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnPZpxOeKzyj7XGGzi8TtaB1+aaBo5c+mqYA2bck/Hm hercules-deploy"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtKq4ewCndIVO4GnSHC14kf96lcluaMcal/gqR7/gpy openpgp:0x69F51905"
            ];
          };
        };

        shell = config.programs.fish.package;
      };
    };
  };
}
