{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (inputs)
    chinese-fonts-overlay
    emacs-overlay
    infix
    nixpkgs
    ;

  inherit (fleet-lib.importers)
    collect
    ;

  inherit (fleet-lib.transformers)
    filterNix
    excludeTopLevelDirs
    removeExtension
    removeInternalPath
    ;

  inherit (lib)
    mapAttrsToList
    removeAttrs
    ;

  fleet-lib = self.lib;

  home = collect ./home [
    filterNix
    removeExtension
    removeInternalPath
  ];

  system = collect ./system [
    filterNix
    removeExtension
    removeInternalPath
  ];

  fleet = collect ./. [
    (excludeTopLevelDirs [
      "home"
      "system"
    ])
    removeExtension
  ];

  profilesToList =
    profiles:
    mapAttrsToList (_: v: v) (
      removeAttrs profiles [
        "__path"
      ]
    );
in
{
  imports = [
    infix.flakeModules.configurations
  ];

  configurations = {
    home = {
      bingshan = {
        inherit (fleet.bingshan)
          home
          ;

        profiles = profilesToList fleet.bingshan.profiles;

        specialArgs = {
          inherit (fleet)
            bingshan
            ;
        };
      };

      ops = {
        inherit (fleet.ops)
          home
          ;

        profiles = profilesToList fleet.ops.profiles;

        specialArgs = {
          inherit (fleet)
            ops
            ;
        };
      };

      root = {
        inherit (fleet.root)
          home
          ;

        profiles = profilesToList fleet.root.profiles;

        specialArgs = {
          inherit (fleet)
            root
            ;
        };
      };

      global = {
        nixpkgs = {
          config = {
            allowUnfree = true;
          };

          input = nixpkgs;

          overlays = [
            chinese-fonts-overlay.overlays.default
            emacs-overlay.overlays.default
            infix.overlays.default
            infix.overlays.emacs-packages
          ];

          system = "x86_64-linux";
        };

        specialArgs = {
          inherit
            home
            inputs
            ;

          inherit (fleet)
            azaleoid
            bingshan
            ops
            root
            ;
        };
      };
    };

    system = {
      azaleoid = {
        inherit (fleet.azaleoid)
          system
          ;

        profiles = profilesToList fleet.azaleoid.profiles;

        modules = [

        ];

        users = {
          bingshan = {
            home = config.configurations.home.bingshan;
            inherit (fleet.bingshan)
              user
              ;
          };

          root = {
            home = config.configurations.home.root;
            inherit (fleet.root)
              user
              ;
          };
        };
      };

      erythron = {
        inherit (fleet.erythron)
          system
          ;

        profiles = profilesToList fleet.erythron.profiles;

        modules = [

        ];

        users = {
          bingshan = {
            home = config.configurations.home.bingshan;
            inherit (fleet.bingshan)
              user
              ;
          };

          root = {
            home = config.configurations.home.root;
            inherit (fleet.root)
              user
              ;
          };
        };
      };

      camellia = {
        inherit (fleet.camellia)
          system
          ;

        profiles = profilesToList fleet.camellia.profiles;

        users = {
          ops = {
            home = config.configurations.home.ops;

            inherit (fleet.ops)
              user
              ;
          };

          root = {
            inherit (fleet.root)
              user
              ;

            home = config.configurations.home.root;
          };
        };
      };

      global = {
        nixpkgs = {
          config = {
            allowUnfree = true;
          };

          input = nixpkgs;

          overlays = [
            chinese-fonts-overlay.overlays.default
            emacs-overlay.overlays.default
            infix.overlays.default
            infix.overlays.emacs-packages
          ];
        };

        specialArgs = {
          inherit
            home
            inputs
            system
            ;

          inherit (fleet)
            azaleoid
            camellia
            erythron
            bingshan
            ops
            root
            ;
        };
      };
    };
  };
}
