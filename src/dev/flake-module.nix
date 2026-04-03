{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins)
    baseNameOf
    ;

  inherit (inputs)
    systems
    ;

  inherit (lib)
    attrNames
    concatStringsSep
    getExe
    makeBinPath
    optional
    pipe
    removeAttrs
    ;

  inherit (lib.generators)
    toINIWithGlobalSection
    ;
in
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devshells = {
        default = {
          ago = {
            editorconfig = {
              data = {
                root = true;

                "*" = {
                  charset = "utf-8";
                  end_of_line = "lf";
                  indent_size = 8;
                  indent_style = "tab";
                  insert_final_newline = true;
                  max_line_length = 70;
                  tab_width = 8;
                };

                "*.el" = {
                  indent_style = "space";
                  indent_size = "unset";
                  tab_width = 2;
                };

                "*.nix" = {
                  indent_style = "space";
                  tab_width = 2;
                  max_line_length = 80;
                };
              };

              engine =
                request:
                let
                  inherit (request)
                    data
                    output
                    ;

                  name = baseNameOf output;

                  value = {
                    globalSection = {
                      root = data.root or true;
                    };

                    sections = removeAttrs data [
                      "root"
                    ];
                  };
                in
                pkgs.writeText name (
                  toINIWithGlobalSection { } value
                );

              output = ".editorconfig";

              packages = with pkgs; [
                editorconfig-checker
              ];
            };

            lefthook = {
              data = {
                pre-commit = {
                  commands = {
                    treefmt = {
                      run = "treefmt --fail-on-change {staged_files}";
                      skip = [
                        "merge"
                        "rebase"
                      ];
                    };
                  };

                  skip = [
                    {
                      ref = "update_flake_lock_action";
                    }
                  ];
                };
              };

              format = "yaml";

              hook = {
                extra =
                  cfg:
                  let
                    inherit (pkgs)
                      lefthook
                      runtimeShell
                      writeScript
                      ;

                    mkScript =
                      stage:
                      writeScript "lefthook-${stage}" ''
                        #!${runtimeShell}
                        [ "$LEFTHOOK" == "0" ] || \
                          ${getExe lefthook} run "${stage}" "$@"
                      '';
                  in
                  pipe cfg [
                    (
                      config:
                      removeAttrs config [
                        "colors"
                        "extends"
                        "skip_output"
                        "source_dir"
                        "source_dir_local"
                      ]
                    )
                    attrNames
                    (map (
                      stage:
                      ''ln -sf "${mkScript stage}" ".git/hooks/${stage}"''
                    ))
                    (
                      stages:
                      optional (stages != [ ]) "mkdir -p .git/hooks"
                      ++ stages
                    )
                    (concatStringsSep "\n")
                  ];
              };

              output = "lefthook.yml";

              packages = with pkgs; [
                lefthook
              ];
            };

            sops = {
              data = {
                creation_rules = [
                  {
                    key_groups = [
                      {
                        pgp = [
                          "D6E9ED4504C41AD2DA16F39631E62A2FC33802BA"
                        ];
                      }
                    ];

                    path_regex = "^src/azaleoid/etc/sops\.yaml$";
                  }
                ];
              };

              format = "yaml";
              output = ".sops.yaml";

              packages = with pkgs; [
                age
                sops
              ];
            };

            treefmt = {
              data = {
                formatter = {
                  nix = {
                    command = "nixfmt";

                    includes = [
                      "*.nix"
                    ];

                    options = [
                      "--width=50"
                    ];
                  };
                };
              };

              format = "toml";
              output = "treefmt.toml";

              packages = with pkgs; [
                nixfmt
                treefmt
              ];
            };
          };

          commands = with pkgs; [
            {
              category = "tools";
              package = git;
            }
            {
              category = "tools";
              package = treefmt;
            }
          ];

          devshell = {
            name = "fleet-dev";

            startup = {
              lefthook = {
                deps = [
                  "treefmt"
                ];
              };
            };
          };
        };
      };

      formatter =
        let
          inherit (pkgs)
            writeShellScriptBin
            treefmt
            ;

          configFile =
            config.devshells.default.agoFiles.treefmt;

          path = makeBinPath config.devshells.default.ago.treefmt.packages;
        in
        writeShellScriptBin "treefmt" ''
          set -euo pipefail
          export PATH=${path}
          exec ${treefmt}/bin/treefmt \
            --config-file=${configFile} \
            --tree-root-file=flake.nix \
            "$@"
        '';
    };

  systems = import systems;
}
