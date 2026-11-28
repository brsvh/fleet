{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  services = {
    garage = {
      enable = mkDefault true;
      package = mkDefault pkgs.garage_2;

      settings = {
        data_dir = mkDefault "/var/lib/garage/data";
        metadata_dir = mkDefault "/var/lib/garage/meta";
        replication_factor = 1;
        rpc_bind_addr = "127.0.0.1:3901";
        rpc_public_addr = "127.0.0.1:3901";

        s3_api = {
          api_bind_addr = "127.0.0.1:3900";
          s3_region = "garage";
        };

        s3_web = {
          bind_addr = mkDefault "127.0.0.1:3902";
          index = mkDefault "index.html";
          root_domain = mkDefault ".web.garage.internal";
        };
      };
    };
  };

  systemd = {
    services = {
      garage = {
        serviceConfig = {
          DynamicUser = false;
          Group = "garage";
          PrivateTmp = true;
          ProtectSystem = "strict";
          UMask = "0077";
          User = "garage";
        };
      };
    };
  };

  users = {
    groups = {
      garage = { };
    };

    users = {
      garage = {
        group = "garage";
        isSystemUser = true;
      };
    };
  };
}
