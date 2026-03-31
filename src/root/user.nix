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
        initialHashedPassword = "$6$OKxyX8LiVd/RmeVj$CwpXDNgDjJ0FtGg71xxy88R8lBnN/IWk.wzlIQA9gvp56beeLT1asQhKsboaA2SB1xUfcdxSqtwB9eZ/NPeoj.";

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
