{ ... }:
{
  nix = {
    settings = {
      # Home Manager activates as this user and needs access to the Nix daemon.
      allowed-users = [
        "archive"
      ];
    };
  };

  users = {
    groups = {
      archive = { };
    };

    users = {
      archive = {
        createHome = true;
        description = "Archive publisher";
        group = "archive";
        home = "/var/lib/archive";
        isSystemUser = true;

        openssh = {
          authorizedKeys = {
            keys = [
              "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtKq4ewCndIVO4GnSHC14kf96lcluaMcal/gqR7/gpy openpgp:0x69F51905"
            ];
          };
        };
      };
    };
  };
}
