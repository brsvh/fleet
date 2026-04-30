{
  inputs = {
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
