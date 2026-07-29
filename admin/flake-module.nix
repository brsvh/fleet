{
  fleet-lib,
  inputs,
  lib,
  projectRoot,
  self,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStringsSep
    elem
    escapeShellArg
    makeBinPath
    mapAttrs
    mkMerge
    ;

  inherit (fleet-lib.importers)
    collect
    ;

  inherit (fleet-lib.transformers)
    camelify
    filterNix
    removeExtension
    removeInternalPath
    ;

  inherit (inputs)
    deploy
    infix
    llm-agents
    nixpkgs
    ;

  fleet-lib = self.lib;

  dev = collect (projectRoot + /admin) [
    camelify
    filterNix
    removeExtension
    removeInternalPath
  ];
in
{
  imports = [
    infix.flakeModules.devshell
  ];

  flake = {
    deploy = {
      nodes =
        let
          azaleoid = self.nixosConfigurations.azaleoid;

          camellia = self.nixosConfigurations.camellia;

          deploy-lib =
            deploy.lib.${camellia.config.nixpkgs.hostPlatform.system};

          erythron = self.nixosConfigurations.erythron;
        in
        {
          azaleoid = {
            fastConnection = true;
            hostname = "azaleoid";

            profiles = {
              system = {
                path = deploy-lib.activate.nixos azaleoid;
                user = "root";
              };
            };

            sshUser = "root";
          };

          camellia = {
            hostname = camellia.config.networking.fqdn;

            profiles = {
              system = {
                path = deploy-lib.activate.nixos camellia;
                user = "root";
              };
            };

            sshUser = "root";
          };

          erythron = {
            fastConnection = true;
            hostname = "erythron";

            profiles = {
              system = {
                path = deploy-lib.activate.nixos erythron;
                user = "root";
              };
            };

            sshUser = "root";
          };
        };
    };
  };

  systems = [
    "x86_64-linux"
  ];

  perSystem =
    {
      config,
      lib,
      pkgs,
      system,
      ...
    }:
    let
      inherit (pkgs)
        curl
        writeShellScriptBin
        treefmt
        ;
    in
    {
      apps = {
        camellia-services-health-check = {
          type = "app";
          program = "${config.packages.camellia-services-health-check}/bin/camellia-services-health-check";
        };
      };

      checks = mkMerge [
        (deploy.lib.${system}.deployChecks self.deploy)
      ];

      _module = {
        args = {
          pkgs = import nixpkgs {
            inherit
              system
              ;

            overlays = [
              infix.overlays.default
              llm-agents.overlays.shared-nixpkgs
            ];
          };
        };
      };

      devshells = mapAttrs (
        _: devshell:
        import devshell {
          inherit
            inputs
            lib
            pkgs
            self
            system
            ;
        }
      ) dev.devshells;

      packages = {
        camellia-services-health-check =
          let
            camellia = self.nixosConfigurations.camellia;

            camellia-config = camellia.config;

            nginx-hosts = attrNames camellia-config.services.nginx.virtualHosts;

            requireNginxHost =
              host:
              if elem host nginx-hosts then
                host
              else
                throw "camellia health check host `${host}` is not configured as an nginx virtual host";

            serviceHealthChecks =
              let
                nextcloudHost = requireNginxHost camellia-config.services.nextcloud.hostName;

                onlyofficeHost = requireNginxHost camellia-config.services.onlyoffice.hostname;

                mtaStsChecks = map (
                  domain:
                  let
                    host = requireNginxHost "mta-sts.${domain}";
                  in
                  {
                    name = "mta-sts:${domain}";
                    url = "https://${host}/.well-known/mta-sts.txt";
                  }
                ) camellia-config.mailserver.domains;
              in
              [
                {
                  name = "nextcloud:status";
                  url = "https://${nextcloudHost}/status.php";
                }
                {
                  name = "nextcloud:whiteboard";
                  url = "https://${nextcloudHost}/whiteboard";
                }
                {
                  name = "onlyoffice:healthcheck";
                  url = "https://${onlyofficeHost}/healthcheck";
                }
              ]
              ++ mtaStsChecks;

            serviceHealthCheckCommands =
              concatMapStringsSep "\n"
                (
                  check:
                  "check_url ${escapeShellArg check.name} ${escapeShellArg check.url}"
                )
                serviceHealthChecks;
          in
          writeShellScriptBin "camellia-services-health-check" ''
            set -euo pipefail

            curl=${curl}/bin/curl
            connect_timeout="''${CAMELLIA_HEALTH_CHECK_CONNECT_TIMEOUT:-10}"
            max_time="''${CAMELLIA_HEALTH_CHECK_MAX_TIME:-30}"
            retries="''${CAMELLIA_HEALTH_CHECK_RETRIES:-2}"
            retry_delay="''${CAMELLIA_HEALTH_CHECK_RETRY_DELAY:-2}"
            failures=0

            check_url() {
              local name="$1"
              local url="$2"

              printf 'checking %-28s %s\n' "$name" "$url"

              if "$curl" \
                --fail \
                --http1.1 \
                --location \
                --silent \
                --show-error \
                --output /dev/null \
                --connect-timeout "$connect_timeout" \
                --max-time "$max_time" \
                --retry "$retries" \
                --retry-all-errors \
                --retry-delay "$retry_delay" \
                "$url"
              then
                printf 'ok       %-28s %s\n' "$name" "$url"
              else
                failures=$((failures + 1))
                printf 'failed   %-28s %s\n' "$name" "$url" >&2
              fi
            }

            ${serviceHealthCheckCommands}

            if [ "$failures" -eq 0 ]; then
              printf 'all camellia service health checks passed\n'
            else
              printf '%s camellia service health check(s) failed\n' \
                "$failures" \
                >&2
              exit 1
            fi
          '';
      };

      formatter =
        let
          inherit (config.devshells.default.files.treefmt)
            file
            packages
            ;
        in
        writeShellScriptBin "treefmt" ''
          set -euo pipefail
          export PATH=${makeBinPath packages}
          exec ${treefmt}/bin/treefmt \
            --config-file=${file} \
            --tree-root-file=flake.nix \
            "$@"
        '';
    };
}
