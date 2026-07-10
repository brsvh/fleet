{
  description = "A personal fleet of workstation and server configurations";

  inputs = {
    blank = {
      url = "git+https://github.com/divnix/blank.git?ref=master";
    };

    blueprint = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };

        systems = {
          follows = "systems";
        };
      };

      url = "git+https://github.com/numtide/blueprint.git?ref=main";
    };

    bun = {
      inputs = {
        flake-parts = {
          follows = "flake-parts";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        systems = {
          follows = "systems";
        };

        treefmt-nix = {
          follows = "treefmt";
        };
      };

      url = "git+https://github.com/nix-community/bun2nix.git?ref=master";
    };

    chinese-fonts-overlay = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/brsvh/chinese-fonts-overlay.git?ref=main";
    };

    crane = {
      url = "git+https://github.com/ipetkov/crane.git?ref=refs/tags/v0.23.4";
    };

    deploy = {
      inputs = {
        flake-compat = {
          follows = "flake-compat";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        utils = {
          follows = "flake-utils";
        };
      };

      url = "git+https://github.com/serokell/deploy-rs.git?ref=master";
    };

    devshell = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/numtide/devshell.git?ref=main";
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

    flake-compat = {
      flake = false;
      url = "git+https://github.com/NixOS/flake-compat.git?ref=master";
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

    hermes-agent = {
      inputs = {
        flake-parts = {
          follows = "flake-parts";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        pyproject-nix = {
          follows = "pyproject";
        };

        pyproject-build-systems = {
          follows = "pyproject-overlay";
        };

        uv2nix = {
          follows = "uv";
        };
      };

      url = "git+https://github.com/NousResearch/hermes-agent.git?ref=refs/tags/v2026.5.16";
    };

    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/home-manager.git?ref=master";
    };

    import-tree = {
      url = "git+https://github.com/denful/import-tree.git?ref=main";
    };

    infix = {
      inputs = {
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

      url = "git+https://github.com/nix-community/lanzaboote.git?ref=refs/tags/v1.1.0";
    };

    llm-agents = {
      inputs = {
        blueprint = {
          follows = "blueprint";
        };

        bun2nix = {
          follows = "bun";
        };

        flake-parts = {
          follows = "flake-parts";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        systems = {
          follows = "systems";
        };

        treefmt-nix = {
          follows = "treefmt";
        };
      };

      url = "git+https://github.com/numtide/llm-agents.nix?ref=main";
    };

    mailserver = {
      inputs = {
        blobs = {
          follows = "mailserver-blobs";
        };

        flake-compat = {
          follows = "flake-compat";
        };

        git-hooks = {
          follows = "blank";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://gitlab.com/simple-nixos-mailserver/nixos-mailserver.git?ref=main";
    };

    mailserver-blobs = {
      flake = false;
      url = "git+https://gitlab.com/simple-nixos-mailserver/blobs.git?ref=master";
    };

    nix-unit = {
      inputs = {
        nix-github-actions = {
          follows = "blank";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        treefmt-nix = {
          follows = "blank";
        };
      };

      url = "git+https://github.com/nix-community/nix-unit.git?ref=main";
    };

    nixpkgs = {
      follows = "nixos";
    };

    nixos = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixos-unstable";
    };

    pyproject = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/pyproject-nix/pyproject.nix.git?ref=master";
    };

    pyproject-overlay = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };

        pyproject-nix = {
          follows = "pyproject";
        };

        uv2nix = {
          follows = "uv";
        };
      };

      url = "git+https://github.com/pyproject-nix/build-system-pkgs.git?ref=master";
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

    systems = {
      url = "git+https://github.com/nix-systems/x86_64-linux.git?ref=main";
    };

    treefmt = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/numtide/treefmt-nix.git?ref=main";
    };

    uv = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };

        pyproject-nix = {
          follows = "pyproject";
        };
      };

      url = "git+https://github.com/pyproject-nix/uv2nix.git?ref=master";
    };
  };

  nixConfig = {
    experimental-features = [
      "ca-derivations"
      "flakes"
    ];

    extra-substituters = [
      "https://bingshan.cachix.org"
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "bingshan.cachix.org-1:ynGuZwJQAfYuM0uq1d2UF8OMxf8uO8GN7V4XDSLYFv8="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
        readDir
        ;

      inherit (nixpkgs.lib)
        attrNames
        filter
        map
        pathExists
        ;

      flakeModules =
        let
          root = ./.;

          tree = readDir root;

          getFlakeModule =
            subdir: root + "/${subdir}/flake-module.nix";

          hasFlakeModule =
            subdir:
            tree.${subdir} == "directory"
            && pathExists (getFlakeModule subdir);
        in
        map getFlakeModule (
          filter hasFlakeModule (attrNames tree)
        );
    in
    mkFlake
      {
        inherit
          inputs
          ;

        specialArgs = {
          infix-lib = infix.lib;
        };
      }
      {
        imports = flakeModules;
      };
}
