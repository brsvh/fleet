{
  config,
  pkgs,
  system,
  ...
}:
{
  imports = [
    system.profiles.nix
  ];

  nix = {
    settings = {
      cores = 8;
      max-jobs = 2;

      substituters = [
        "https://cache.bingshan.org?priority=35"
      ];

      trusted-public-keys = [
        "cache.bingshan.org-1:HqcG/vJ7jeSLU48jV4yg8Ot+rUPP2v0vIAAnDEqVSvk="
      ];

      trusted-users = [
        "hercules-ci-store"
      ];
    };

    sshServe = {
      enable = true;

      keys = [
        ''restrict,from="100.64.0.3" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6utBNc5//VxGVx4LDk88ZckW0v0qqhF+4p9i6ga3oI azaleoid-to-magnolia-nix-builder''
      ];

      trusted = true;
    };
  };

  users = {
    groups = {
      hercules-ci-store = { };
    };

    users = {
      hercules-ci-store = {
        description = "Hercules CI shared store";
        group = "hercules-ci-store";
        isSystemUser = true;
        shell = pkgs.bashInteractive;

        openssh = {
          authorizedKeys = {
            # The legacy store protocol accepts build outputs over authenticated SSH.
            keys = [
              ''restrict,from="100.64.0.2",command="${config.nix.package}/bin/nix-store --serve --write" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPR6v5vp2UJ2cEWrmibWSVpdJFgyC8JjTF7TJU6a6Wxi hercules-ci-magnolia''
              ''restrict,from="100.64.0.4",command="${config.nix.package}/bin/nix-store --serve --write" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICl+E0oro1AQJYs52ygwtE5JdcivqLx7oS7gIqbkg6Wo hercules-ci-erythron''
            ];
          };
        };
      };
    };
  };
}
