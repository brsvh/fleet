{
  description = "A personal fleet of workstation and server configurations";

  inputs = {
    blank = {
      url = "git+https://github.com/divnix/blank.git?ref=master";
    };

    crane = {
      url = "git+https://github.com/ipetkov/crane.git?ref=refs/tags/v0.23.2";
    };

    disko = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/disko.git?ref=master";
    };

    emacs-overlay = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };

        nixpkgs-stable = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/emacs-overlay.git?ref=master";
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

    lanzaboote = {
      inputs = {
        crane = {
          follows = "crane";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        pre-commit = {
          follows = "blank";
        };

        rust-overlay = {
          follows = "rust-overlay";
        };
      };

      url = "git+https://github.com/nix-community/lanzaboote.git?ref=refs/tags/v1.0.0";
    };

    nixpkgs = {
      follows = "nixos";
    };

    nixos = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixos-unstable";
    };

    rust-overlay = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/oxalica/rust-overlay.git?ref=master";
    };

    sops = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/Mic92/sops-nix.git?ref=master";
    };
  };

  nixConfig = {
    experimental-features = [
      "ca-derivations"
      "flakes"
    ];

    extra-substituters = [
      "https://bingshan.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "bingshan.cachix.org-1:ynGuZwJQAfYuM0uq1d2UF8OMxf8uO8GN7V4XDSLYFv8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{
      emacs-overlay,
      flake-parts,
      infix,
      nixpkgs,
      systems,
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

        flake = {
          homeModules = home.modules;
          nixosModules = system.modules;
        };

        nixosConfigurations = {
          azaleoid = {
            allowUnfree = true;

            directory = fleet.azaleoid.__path;

            overlays = [
              emacs-overlay.overlays.default
              infix.overlays.default
              infix.overlays.emacs-packages
            ];

            specialArgs = {
              inherit
                home
                infix
                system
                ;
            };

            users = {
              bingshan = {
                directory = fleet.bingshan.__path;
              };

              root = {
                directory = fleet.root.__path;
              };
            };
          };

          erythron = {
            allowUnfree = true;

            directory = fleet.erythron.__path;

            overlays = [
              emacs-overlay.overlays.default
              infix.overlays.default
              infix.overlays.emacs-packages
            ];

            specialArgs = {
              inherit
                home
                infix
                system
                ;
            };

            users = {
              bingshan = {
                directory = fleet.bingshan.__path;
              };

              root = {
                directory = fleet.root.__path;
              };
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

        systems = import systems;
      };
}
