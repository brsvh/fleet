{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    mkIf
    mkOption
    types
    ;

  cfg = config.services.hercules-ci-agent;

  repositoryPatterns = concatMapStringsSep " | " (
    url: escapeShellArg url
  ) cfg.noIFDRepositories;

  worker = pkgs.writeShellScript "hercules-ci-agent-worker" ''
    if [ "''${1:-}" = eval ]; then
      repository="''${2:-}"

      if [ -z "$repository" ]; then
        echo 'Missing repository URL in Hercules evaluation task' >&2
        exit 78
      fi

      case "''${repository%/}" in
        ${repositoryPatterns})
          export NIX_CONFIG="''${NIX_CONFIG:-}
    allow-import-from-derivation = false"
          ;;
      esac
    fi

    exec ${cfg.package}/bin/hercules-ci-agent-worker "$@"
  '';

  workerDirectory =
    pkgs.runCommand "hercules-ci-worker-policy" { }
      ''
        mkdir -p "$out"
        ln -s ${worker} "$out/hercules-ci-agent-worker"
        ln -s ${cfg.package}/bin/hercules-ci-nix-daemon \
          "$out/hercules-ci-nix-daemon"
      '';
in
{
  options = {
    services = {
      hercules-ci-agent = {
        noIFDRepositories = mkOption {
          default = [ ];

          description = ''
            Canonical repository web URLs whose Hercules evaluations must
            not realize derivations. Other repositories retain their Nix
            settings. Evaluation without repository metadata fails closed.
          '';

          type = with types; listOf str;
        };
      };
    };
  };

  config =
    mkIf (cfg.enable && cfg.noIFDRepositories != [ ])
      {
        assertions = [
          {
            # The worker argv and Cabal relocation hook are audited for this release.
            assertion =
              (cfg.package.version or "") == "0.10.8";
            message = "Review the Hercules worker interface before updating the agent's repository IFD policy.";
          }
          {
            # Worker options arrive after NIX_CONFIG and must not override the policy.
            assertion =
              !(
                cfg.settings.nixSettings
                  ? allow-import-from-derivation
              );
            message = "Use noIFDRepositories without an agent-wide allow-import-from-derivation setting.";
          }
        ];

        systemd = {
          services = {
            hercules-ci-agent = {
              environment = {
                hercules_ci_agent_bindir = "${workerDirectory}";
              };
            };
          };
        };
      };
}
