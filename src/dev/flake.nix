{
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

        import-tree = {
          follows = "import-tree";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        systems = {
          follows = "systems";
        };

        treefmt-nix = {
          follows = "blank";
        };
      };

      url = "git+https://github.com/nix-community/bun2nix.git?ref=master";
    };

    devshell = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };

      url = "git+https://github.com/numtide/devshell.git?ref=main";
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

      url = "github:numtide/flake-utils/main";
    };

    import-tree = {
      url = "git+https://github.com/denful/import-tree.git?ref=main";
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
          follows = "blank";
        };
      };

      url = "git+https://github.com/numtide/llm-agents.nix?ref=main";
    };

    nixago = {
      inputs = {
        flake-utils = {
          follows = "flake-utils";
        };

        nixpkgs = {
          follows = "nixpkgs";
        };

        nixago-exts = {
          follows = "nixago-extensions";
        };
      };

      url = "git+https://github.com/nix-community/nixago.git?ref=master";
    };

    nixago-extensions = {
      inputs = {
        flake-utils = {
          follows = "nixago/flake-utils";
        };

        nixago = {
          follows = "nixago";
        };

        nixpkgs = {
          follows = "nixago/nixpkgs";
        };
      };

      url = "git+https://github.com/nix-community/nixago-extensions.git?ref=master";
    };

    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixpkgs-unstable";
    };

    systems = {
      url = "git+https://github.com/nix-systems/x86_64-linux.git?ref=main";
    };
  };

  outputs = { ... }: { };
}
