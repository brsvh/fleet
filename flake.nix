{
  description = "A personal fleet of workstation and server configurations";

  inputs = {
    disko = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/disko.git?ref=master";
    };

    facter = {
      url = "git+https://github.com/numtide/nixos-facter-modules.git?ref=main";
    };

    flake-parts = {
      inputs = {
        nixpkgs-lib = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/hercules-ci/flake-parts.git?ref=main";
    };

    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/home-manager.git?ref=master";
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
      follows = "nixos";
    };

    nixos = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixos-unstable";
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
        mapAttrsRecursiveCond'
        stemOf
        ;

      inherit (nixpkgs.lib)
        elem
        filterAttrs
        filterAttrsRecursive
        hasSuffix
        isAttrs
        last
        nameValuePair
        pipe
        toCamelCase
        ;

      camelifyAttrs = mapAttrsRecursive' (
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
      );

      liftDefaultAttrs =
        mapAttrsRecursiveCond'
          (v: !(isAttrs v && v ? default))
          (
            path: v:
            nameValuePair (stemOf (last path)) (
              if isAttrs v && v ? default then v.default else v
            )
          );

      removeExtension = mapAttrsRecursive' (
        path: value:
        let
          basename = last path;
        in
        nameValuePair (
          if basename == "__path" then
            "__path"
          else
            (stemOf basename)
        ) value
      );

      removePathAttrs = filterAttrsRecursive (
        name: _: name != "__path"
      );

      excludeTopLevelDirs =
        dirs: filterAttrs (name: _: !(elem name dirs));

      keepOnlyNixAttrs = filterAttrsRecursive (
        name: value:
        if (isAttrs value) || (name == "__path") then
          true
        else
          hasSuffix ".nix" (toString value)
      );

      collect = dir: fns: pipe (dirToAttrs dir) fns;

      dev = collect ./src/dev [
        keepOnlyNixAttrs
        camelifyAttrs
      ];

      fleet = collect ./src [
        (excludeTopLevelDirs [
          "dev"
          "home"
          "system"
        ])
        keepOnlyNixAttrs
        camelifyAttrs
      ];

      home = collect ./src/home [
        removeExtension
        removePathAttrs
        keepOnlyNixAttrs
      ];

      system = collect ./src/system [
        removeExtension
        removePathAttrs
        keepOnlyNixAttrs
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
          infix.flakeModules.nixosConfigurations
        ];

        nixosConfigurations = {
          azaleoid = {
            directory = fleet.azaleoid.__path;

            specialArgs = {
              inherit
                home
                infix
                system
                ;
            };
          };
        };

        partitionedAttrs = {
          devShells = "dev";
          formatter = "dev";
        };

        partitions = {
          dev = {
            extraInputsFlake = dev.__path;

            module = {
              imports = [
                infix.flakeModules.devshell
                dev.flakeModule
              ];
            };
          };
        };

        systems = [ ];
      };
}
