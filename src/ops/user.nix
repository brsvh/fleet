{
  config,
  system,
  ...
}:
{
  imports = [
    system.modules.users-groups
    system.profiles.fish
  ];

  users = {
    users = {
      ops = {
        description = "Operations";

        extraGroups = [
          "systemd-journal"
          "wheel"
        ];

        initialHashedPassword = "$y$j9T$f8cxmklj9ft1Sq6iZnMcM1$DnX/HiX8v384G5eUVCYChHxk44Z0348WP/s.btjRUH.";
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
