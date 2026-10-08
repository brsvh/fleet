{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    ;

  cfg = config.services.hercules-ci-agent;

in
{
  imports = [
    system.modules.hercules-ci-worker
  ];

  config = mkMerge [
    {
      environment = {
        systemPackages = with pkgs; [
          hci
        ];
      };

      services = {
        hercules-ci-agent = {
          # Hosts opt in and set concurrency and cache read settings.
          settings = {
            baseDirectory = mkDefault "/var/lib/hercules-ci-agent";

            nixSettings = {
              # CI tasks build locally without changing ordinary clients.
              builders = "";
              post-build-hook = "";
            };

            # Hosts providing Effect credentials override this with a runtime secret.
            secretsJsonPath = mkDefault (
              (pkgs.formats.json { }).generate
                "hercules-ci-secrets.json"
                { }
            );

            staticSecretsDirectory = mkDefault "/run/secrets/hercules-ci";
          };
        };
      };
    }
    (mkIf cfg.enable {
      nix = {
        settings = {
          allowed-users = [
            "hercules-ci-agent"
          ];

          experimental-features = [
            "flakes"
            "nix-command"
          ];
        };
      };

      systemd = {
        services = {
          hercules-ci-agent = {
            serviceConfig = {
              UMask = "0077";
            };
          };
        };
      };
    })
  ];
}
