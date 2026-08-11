{
  config,
  inputs,
  lib,
  projectRoot,
  self,
  ...
}:
let
  inherit (inputs)
    chinese-fonts-overlay
    emacs-bs
    emacs-jieba-rs
    emacs-overlay
    emacs-proofread
    infix
    llm-agents
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

  home = collect (projectRoot + /src/home) [
    filterNix
    removeExtension
    removeInternalPath
  ];

  system = collect (projectRoot + /src/system) [
    filterNix
    removeExtension
    removeInternalPath
  ];

  fleet = collect (projectRoot + /src) [
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
            emacs-bs.overlays.default
            emacs-jieba-rs.overlays.default
            emacs-overlay.overlays.default
            emacs-proofread.overlays.default
            infix.overlays.default
            infix.overlays.emacs-packages
            llm-agents.overlays.shared-nixpkgs
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

        users = {
          bingshan = {
            inherit (fleet.bingshan)
              user
              ;

            home = config.configurations.home.bingshan // {
              profiles =
                config.configurations.home.bingshan.profiles
                ++ [
                  fleet.bingshan.special-profiles.gnome
                ];
            };
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

        users = {
          bingshan = {
            inherit (fleet.bingshan)
              user
              ;

            home = config.configurations.home.bingshan // {
              profiles =
                config.configurations.home.bingshan.profiles
                ++ [
                  fleet.bingshan.special-profiles.gnome
                ];
            };
          };

          root = {
            inherit (fleet.root)
              user
              ;

            home = config.configurations.home.root;
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

      magnolia = {
        inherit (fleet.magnolia)
          system
          ;

        profiles = profilesToList fleet.magnolia.profiles;

        users = {
          bingshan = {
            inherit (fleet.bingshan)
              user
              ;

            home = config.configurations.home.bingshan // {
              profiles =
                config.configurations.home.bingshan.profiles
                ++ [
                  (
                    {
                      config,
                      lib,
                      pkgs,
                      ...
                    }:
                    let
                      inherit (lib)
                        escapeShellArg
                        getExe
                        ;

                      hostname = "magnolia.tail.bingshan.org";

                      dir = "${config.xdg.dataHome}/krdpserver";

                      crt = "${dir}/krdp.crt";

                      key = "${dir}/krdp.key";

                      mkCert = pkgs.writeShellApplication {
                        name = "create-krdpserver-certificate";

                        runtimeInputs = with pkgs; [
                          coreutils
                          openssl
                          systemd
                        ];

                        text = ''
                          dir=${escapeShellArg dir}
                          crt_file=${escapeShellArg crt}
                          key_file=${escapeShellArg key}
                          hostname=${escapeShellArg hostname}
                          key_usage=critical,digitalSignature
                          key_usage="$key_usage,keyEncipherment"

                          install -d -m 0700 "$dir"

                          is_valid=true

                          if [ ! -s "$crt_file" ] \
                            || [ ! -s "$key_file" ]; then
                            is_valid=false
                          elif ! openssl x509 -checkend 2592000 \
                            -in "$crt_file" -noout >/dev/null 2>&1; then
                            is_valid=false
                          elif ! openssl x509 -checkhost "$hostname" \
                            -in "$crt_file" -noout >/dev/null 2>&1; then
                            is_valid=false
                          elif ! openssl pkey -check \
                            -in "$key_file" -noout >/dev/null 2>&1; then
                            is_valid=false
                          fi

                          if [ "$is_valid" = true ]; then
                            exit 0
                          fi

                          tmp_dir="$(mktemp -d "$dir/.crt_file.XXXXXX")"

                          trap 'rm -rf -- "$tmp_dir"' EXIT
                          umask 077

                          openssl req \
                            -addext "subjectAltName=DNS:$hostname" \
                            -addext "basicConstraints=critical,CA:FALSE" \
                            -addext "keyUsage=$key_usage" \
                            -addext "extendedKeyUsage=serverAuth" \
                            -days 825 \
                            -keyout "$tmp_dir/krdp.key" \
                            -newkey rsa:3072 \
                            -nodes \
                            -out "$tmp_dir/krdp.crt" \
                            -sha256 \
                            -subj "/CN=$hostname" \
                            -x509

                          chmod 0600 "$tmp_dir/krdp.key"
                          chmod 0644 "$tmp_dir/krdp.crt"

                          mv "$tmp_dir/krdp.key" "$key_file"
                          mv "$tmp_dir/krdp.crt" "$crt_file"

                          systemctl --user --no-block try-restart \
                            app-org.kde.krdpserver.service || true
                        '';
                      };
                    in
                    {
                      programs = {
                        plasma = {
                          configFile = {
                            krdpserverrc = {
                              General = {
                                Autostart = true;
                                Certificate = crt;
                                CertificateKey = key;
                                SystemUserEnabled = true;
                              };
                            };
                          };
                        };
                      };

                      systemd = {
                        user = {
                          services = {
                            krdpserver-certificate = {
                              Install = {
                                WantedBy = [
                                  "graphical-session.target"
                                ];
                              };

                              Service = {
                                ExecStart = getExe mkCert;

                                Type = "oneshot";
                              };

                              Unit = {
                                Before = [
                                  "app-org.kde.krdpserver.service"
                                ];

                                Description =
                                  "Generate the KRDP " + "server certificate";

                                PartOf = [
                                  "graphical-session.target"
                                ];
                              };
                            };
                          };
                        };
                      };
                    }
                  )
                  fleet.bingshan.special-profiles.nvidia
                  fleet.bingshan.special-profiles.plasma
                  fleet.bingshan.special-profiles.steam
                ];
            };
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
            emacs-bs.overlays.default
            emacs-jieba-rs.overlays.default
            emacs-overlay.overlays.default
            emacs-proofread.overlays.default
            infix.overlays.default
            infix.overlays.emacs-packages
            llm-agents.overlays.shared-nixpkgs
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
            magnolia
            bingshan
            ops
            root
            ;
        };
      };
    };
  };
}
