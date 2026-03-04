{
  description = "A personal fleet of workstation and server configurations";

  inputs = {
    flake-parts = {
      inputs = {
        nixpkgs-lib = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/hercules-ci/flake-parts.git?ref=main";
    };

    infix = {
      inputs = {
        flake-parts = {
          follows = "flake-parts";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://codeberg.org/bingshan/infix.git?ref=main";
    };

    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixpkgs-unstable";
    };
  };

  nixConfig = {
    experimental-features = [
      "ca-derivations"
      "flakes"
    ];
  };

  outputs =
    inputs@{
      flake-parts,
      infix,
      nixpkgs,
      ...
    }:
    let
      inherit (flake-parts.lib)
        mkFlake
        ;

      inherit (infix.lib)
        dirToAttrs
        mapAttrsRecursive'
        stemOf
        ;

      inherit (nixpkgs.lib)
        filterAttrsRecursive
        hasSuffix
        isAttrs
        last
        nameValuePair
        pipe
        toCamelCase
        ;

      parts = pipe (dirToAttrs ./.) [
        (filterAttrsRecursive (
          name: value:
          if (isAttrs value) || (name == "__path") then
            true
          else
            hasSuffix ".nix" (toString value)
        ))
        (mapAttrsRecursive' (
          path: value:
          let
            basename = last path;
          in
          nameValuePair (
            if basename == "__path" then
              "__path"
            else
              (toCamelCase (stemOf basename))
          ) value
        ))
      ];
    in
    mkFlake
      {
        inherit
          inputs
          ;
      }
      {
        imports = [
          flake-parts.flakeModules.partitions
        ];

        partitionedAttrs = {
          devShells = "dev";
          formatter = "dev";
        };

        partitions = {
          dev = {
            extraInputsFlake = parts.dev.__path;

            module = {
              imports = [
                infix.flakeModules.devshell
                parts.dev.flakeModule
              ];
            };
          };
        };

        systems = [ ];
      };
}
