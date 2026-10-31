{
  config,
  lib,
  pkgs,
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
            environment = {
              # Avoid HTTP/2 stream resets during GitHub source fetches.
              GIT_CONFIG_COUNT = "1";
              GIT_CONFIG_KEY_0 = "http.https://github.com/.version";
              GIT_CONFIG_VALUE_0 = "HTTP/1.1";
            };

            serviceConfig = {
              UMask = "0077";
            };
          };
        };
      };
    })
  ];
}
