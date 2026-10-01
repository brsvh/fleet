{
  config,
  pkgs,
  system,
  ...
}:
let
  publicKey = "magnolia.tail.bingshan.org-1:VDtUX3qdn2o0sknJSDf0abndR7RwqnyNU4V4GKKJZpQ=";

  sshKey =
    config.sops.secrets.hercules-ci-store-ssh-key.path;
in
{
  imports = [
    system.profiles.hercules-ci
  ];

  nix = {
    settings = {
      extra-system-features = [ "deploy" ];
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

  services = {
    hercules-ci-agent = {
      enable = true;

      settings = {
        binaryCachesPath =
          (pkgs.formats.json { }).generate
            "hercules-ci-binary-caches.json"
            {
              magnolia-cache = {
                kind = "NixCache";

                publicKeys = [
                  publicKey
                ];

                signingKeys = [ ];
                storeURI = "ssh://hercules-ci-store@100.64.0.2?ssh-key=${sshKey}";
              };
            };

        clusterJoinTokenPath =
          config.sops.secrets.hercules-ci-cluster-join-token.path;
        concurrentTasks = 2;

        nixSettings = {
          cores = "8";
          extra-substituters = "https://magnolia.tail.bingshan.org?priority=30";
          extra-trusted-public-keys = publicKey;
          max-jobs = "2";
        };

        secretsJsonPath =
          config.sops.secrets.hercules-ci-effects-secrets.path;
      };
    };
  };

  sops = {
    secrets = {
      hercules-ci-cluster-join-token = {
        key = "hercules-ci/cluster-join-token";
        owner = "hercules-ci-agent";

        restartUnits = [
          "hercules-ci-agent.service"
        ];
      };

      hercules-ci-effects-secrets = {
        key = "hercules-ci/effects-secrets";
        owner = "hercules-ci-agent";

        restartUnits = [
          "hercules-ci-agent.service"
        ];
      };

      hercules-ci-store-ssh-key = {
        key = "hercules-ci/store-ssh-key";
        owner = "hercules-ci-agent";

        restartUnits = [
          "hercules-ci-agent.service"
        ];
      };
    };
  };

  systemd = {
    services = {
      hercules-ci-agent = {
        after = [
          "acme-order-renew-${config.networking.fqdn}.service"
          "nginx.service"
          "sops-install-secrets.service"
          "tailscaled.service"
        ];

        environment = {
          NIX_SSHOPTS = "-o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes";
        };

        wants = [
          "acme-order-renew-${config.networking.fqdn}.service"
          "nginx.service"
          "tailscaled.service"
        ];
      };
    };
  };
}
