{
  camellia,
  config,
  pkgs,
  system,
  ...
}:
let
  garageEnvironment = pkgs.writeText "garage.env" ''
    GARAGE_RPC_SECRET_FILE=${
      config.sops.secrets."garage/rpc-secret".path
    }
  '';
in
{
  imports = [
    camellia.profiles.sops
    system.profiles.garage
  ];

  services = {
    garage = {
      environmentFile = garageEnvironment;
    };
  };

  sops = {
    secrets = {
      "garage/rpc-secret" = {
        owner = "garage";

        restartUnits = [
          "garage.service"
        ];
      };
    };
  };
}
