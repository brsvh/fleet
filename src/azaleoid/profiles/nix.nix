{
  config,
  system,
  ...
}:
{
  imports = [
    system.profiles.nix
  ];

  nix = {
    buildMachines = [
      {
        # Keep the connection on the IPv4 address allowed by the builder key.
        hostName = "100.64.0.2";
        maxJobs = 2;
        protocol = "ssh-ng";
        speedFactor = 2;
        sshKey =
          config.sops.secrets.nix-builder-ssh-key.path;
        sshUser = "nix-ssh";
        system = "x86_64-linux";

        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];

    distributedBuilds = true;

    settings = {
      substituters = [
        "http://magnolia.tail.bingshan.org:5000?priority=30"
        "https://cache.bingshan.org?priority=35"
      ];

      trusted-public-keys = [
        "cache.bingshan.org-1:HqcG/vJ7jeSLU48jV4yg8Ot+rUPP2v0vIAAnDEqVSvk="
        "magnolia.tail.bingshan.org-1:VDtUX3qdn2o0sknJSDf0abndR7RwqnyNU4V4GKKJZpQ="
      ];
    };
  };

  programs = {
    ssh = {
      knownHosts = {
        magnolia = {
          hostNames = [
            "magnolia.tail.bingshan.org"
            "100.64.0.2"
          ];

          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlZHUHM5kNwUFOA54cF6LDrwiw9VUQpq1M7IhwyoyTQ root@magnolia";
        };
      };
    };
  };

  sops = {
    secrets = {
      nix-builder-ssh-key = {
        key = "nix-builder/ssh-key";
      };
    };
  };
}
