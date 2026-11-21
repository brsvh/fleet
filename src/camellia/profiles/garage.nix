{
  camellia,
  config,
  pkgs,
  system,
  ...
}:
let
  inherit (config.sops)
    secrets
    ;
in
{
  imports = [
    camellia.profiles.sops
    system.modules.garage-provision
    system.profiles.garage
  ];

  services = {
    garage = {
      environmentFile = pkgs.writeText "garage.env" ''
        GARAGE_RPC_SECRET_FILE=${
          secrets."garage/rpc-secret".path
        }
      '';

      provision = {
        buckets = {
          nextcloud = {
            keys = {
              nextcloud = true;
            };
          };
        };

        capacity = 53687091200;
        enable = true;

        keys = {
          nextcloud = {
            id = "GK74f5107bc2ede82b9f049e23";
            secretFile =
              secrets."nextcloud/s3-secret-key".path;
          };
        };

        rpcSecretFile = secrets."garage/rpc-secret".path;
        zone = "camellia";
      };
    };
  };

  sops = {
    secrets = {
      "garage/rpc-secret" = {
        owner = "garage";

        restartUnits = [
          "garage.service"
          "garage-configure.service"
        ];
      };
    };
  };

  systemd = {
    services = {
      garage-configure = {
        before = [
          "nextcloud-setup.service"
        ];
      };
    };
  };
}
