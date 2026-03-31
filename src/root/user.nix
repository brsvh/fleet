{
  system,
  config,
  ...
}:
{
  imports = [
    system.profiles.fish
  ];

  users = {
    users = {
      root = {
        initialHashedPassword = "$y$j9T$SLgyzhjD5N85EYmdCWicI/$3Qei1rSEjsmTwCEKAXwqXsEpcQx4OB5GAuewfp0vz74";

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
