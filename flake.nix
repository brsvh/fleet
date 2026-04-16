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

    flake-utils = {
      inputs = {
        systems = {
          follows = "systems";
        };
      };

      url = "git+https://github.com/numtide/flake-utils.git?ref=main";
    };

    git-hooks = {
      follows = "blank";
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
          follows = "git-hooks";
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

    openclaw = {
      inputs = {
        flake-utils = {
          follows = "flake-utils";
        };

        home-manager = {
          follows = "home-manager";
        };

        nix-steipete-tools = {
          follows = "steipete-tools";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/openclaw/nix-openclaw.git?ref=main";
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

    steipete-tools = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/openclaw/nix-steipete-tools.git?ref=main";
    };

    systems = {
      url = "git+https://github.com/nix-systems/default-linux.git?ref=main";
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
      emacs-overlay,
      flake-parts,
      infix,
      openclaw,
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
            allowUnsupportedSystem = true;

            directory = fleet.azaleoid.__path;

            overlays = [
              emacs-overlay.overlays.default
              infix.overlays.default
              infix.overlays.emacs-packages
              openclaw.overlays.default
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
              openclaw.overlays.default
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
