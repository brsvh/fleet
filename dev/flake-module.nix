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
