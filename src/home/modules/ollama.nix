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
    getExe
    mapAttrsToList
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.services.ollama;

  package =
    if cfg.acceleration == null then
      cfg.package
    else
      cfg.package.override {
        inherit (cfg)
          acceleration
          ;
      };

  host = "${cfg.host}:${toString cfg.port}";

  xdgModelsDir = "${config.xdg.dataHome}/ollama";

  commands = concatMapStringsSep "\n" (
    model:
    let
      args = escapeShellArg model;
    in
    ''
      if ! ${getExe package} show ${args} >/dev/null 2>&1; then
        ${getExe package} pull ${args}
      fi
    ''
  ) cfg.models;

  loader = pkgs.writeShellScript "ollama-model-loader" ''
    set -euo pipefail

    export OLLAMA_HOST=${escapeShellArg host}

    attempt=0
    until ${getExe package} list >/dev/null 2>&1; do
      attempt=$((attempt + 1))
      if [ "$attempt" -ge ${toString cfg.loader.startupRetries} ]; then
        ${getExe package} list >/dev/null
      fi

      ${pkgs.coreutils}/bin/sleep 1
    done

    ${commands}
  '';
in
{
  options = {
    services = {
      ollama = {
        models = mkOption {
          default = [ ];

          description = ''
            Ollama model references to pull for this user.
          '';

          example = [
            "qwen3:1.7b"
          ];

          type = with types; listOf str;
        };

        loader = {
          enable = mkOption {
            default = true;

            description = ''
              Whether to create a user service that pulls configured Ollama
              models after the Ollama server becomes available.
            '';

            type = types.bool;
          };

          startupRetries = mkOption {
            default = 30;

            description = ''
              Number of one-second attempts to wait for the Ollama server
              before surfacing the server readiness failure.
            '';

            type = types.ints.positive;
          };
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && config.xdg.enable) {
      home = {
        sessionVariables = {
          OLLAMA_MODELS = mkDefault xdgModelsDir;
        };
      };

      services = {
        ollama = {
          environmentVariables = {
            OLLAMA_MODELS = mkDefault xdgModelsDir;
          };
        };
      };
    })
    (mkIf
      (
        cfg.enable
        && cfg.loader.enable
        && cfg.models != [ ]
      )
      {
        systemd = {
          user = {
            services = {
              ollama-model-loader = {
                Install = {
                  WantedBy = [
                    "default.target"
                  ];
                };

                Service = {
                  Environment = mapAttrsToList (
                    name: value: "${name}=${value}"
                  ) cfg.environmentVariables;
                  ExecStart = "${loader}";
                  Type = "oneshot";
                };

                Unit = {
                  After = [
                    "network.target"
                    "ollama.service"
                  ];
                  Description = "Pull Ollama models";
                  Wants = [
                    "ollama.service"
                  ];
                };
              };
            };
          };
        };
      }
    )
  ];
}
