{
  fleet-lib,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib)
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

  dev = collect ./. [
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
          camellia = self.nixosConfigurations.camellia;

          deploy-lib =
            deploy.lib.${camellia.config.nixpkgs.hostPlatform.system};

          erythron = self.nixosConfigurations.erythron;
        in
        {
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
        writeShellScriptBin
        treefmt
        ;
    in
    {
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
              llm-agents.overlays.default
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
            ;
        }
      ) dev.devshells;

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
