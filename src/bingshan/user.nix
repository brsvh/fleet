{
  config,
  system,
  ...
}:
{
  imports = [
    system.profiles.fish
  ];

  users = {
    users = {
      bingshan = {
        description = "Bingshan Chang";

        extraGroups = [
          "audio"
          "davfs2"
          "dialout"
          "jackaudio"
          "kvm"
          "libvirtd"
          "lp"
          "network"
          "networkmanager"
          "scanner"
          "systemd-journal"
          "video"
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
