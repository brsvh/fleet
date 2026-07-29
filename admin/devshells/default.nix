{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (inputs)
    plasma-manager
    ;

  inherit (lib)
    baseNameOf
    concatStringsSep
    getExe
    map
    removeAttrs
    ;

  inherit (lib.generators)
    toINIWithGlobalSection
    ;

  inherit (pkgs)
    mdformat
    writeText
    ;

  inherit (pkgs.formats)
    toml
    yaml
    ;

  plasma-manager-pkgs =
    plasma-manager.packages.${system};
in
{
  commands = with pkgs; [
    {
      category = "[deployment]";
      name = "deploy";
      package = deploy-rs;
    }
    {
      category = "[tools]";
      help = "Convert Plasma configuration file to Nix";
      package = plasma-manager-pkgs.default;
    }
    {
      category = "[tools]";
      package = git;
    }
    {
      category = "[development]";
      name = "specify";
      package = spec-kit;
    }
    {
      category = "[tools]";
      package = treefmt;
    }
  ];

  files = {
    editorconfig = rec {
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

        "*.md" = {
          indent_size = 2;
          indent_style = "space";
          max_line_length = 80;
          trim_trailing_whitespace = false;
        };

        "*.nix" = {
          indent_style = "space";
          max_line_length = 80;
          tab_width = 2;
        };
      };

      generator =
        data:
        let
          name = baseNameOf path;

          value = {
            globalSection = {
              root = data.root or true;
            };

            sections = removeAttrs data [
              "root"
            ];
          };
        in
        writeText name (toINIWithGlobalSection { } value);

      packages = with pkgs; [
        editorconfig-checker
      ];

      path = ".editorconfig";
    };

    prek = rec {
      data = {
        default_install_hook_types = [
          "pre-commit"
        ];

        repos = [
          {
            repo = "local";

            hooks = [
              {
                entry = "treefmt --fail-on-change";
                id = "treefmt";
                language = "system";
                name = "treefmt";

                stages = [
                  "pre-commit"
                ];
              }
            ];
          }
        ];
      };

      deps = [
        "treefmt"
      ];

      generator =
        data: (toml { }).generate (baseNameOf path) data;

      hook =
        let
          inherit (pkgs)
            git
            prek
            runtimeShell
            writeScript
            ;

          mkInstall = stage: ''
            if gitDir="$(
              ${getExe git} -C "$PRJ_ROOT" \
                rev-parse --absolute-git-dir \
                2>/dev/null
            )"; then
              mkdir -p "$gitDir/hooks"
              ln -sf "${mkScript stage}" "$gitDir/hooks/${stage}"
            fi
          '';

          mkScript =
            stage:
            writeScript "prek-${stage}" ''
              #!${runtimeShell}
              if [ "''${PREK:-}" = "0" ] || [ "''${LEFTHOOK:-}" = "0" ]; then
                exit 0
              fi

              gitDir="$(
                ${getExe git} -C "$PRJ_ROOT" \
                  rev-parse --absolute-git-dir \
                  2>/dev/null || true
              )"

              if [ -n "$gitDir" ]; then
                if [ -e "$gitDir/MERGE_HEAD" ] \
                  || [ -d "$gitDir/rebase-apply" ] \
                  || [ -d "$gitDir/rebase-merge" ]; then
                  exit 0
                fi

                ref="$(
                  ${getExe git} -C "$PRJ_ROOT" \
                    symbolic-ref --quiet --short HEAD \
                    2>/dev/null || true
                )"

                if [ "$ref" = "update_flake_lock_action" ]; then
                  exit 0
                fi
              fi

              exec ${getExe prek} -C "$PRJ_ROOT" run --stage "${stage}" "$@"
            '';
        in
        concatStringsSep "\n" (
          map mkInstall data.default_install_hook_types
        );

      packages = with pkgs; [
        git
        prek
      ];

      path = "prek.toml";
    };

    sops = rec {
      data =
        let
          azaleoid = "age16dqp5jglesqrl3g683dv7zkahuaq6h3e9w88je70cgd0rhj53edq2a00xm";

          bingshan = "age170frnnagdmfajd686ahxztn7suxn7890jsqeh4fgpugltrnm4cpqmkdd0h";

          camellia = "age194qvjfwdnntwx9200e5ygepx0fppwh8034ljnzvzhc9zfxn9vfyq90m0z0";

          erythron = "age1svqryg3zmt67c6229sfem69hhe8aqup7v82r9req0vmrhd4mk9ks6gh4an";

          magnolia = "age10eqf23zmmhrdhlcxtk47as2e582e7kws35478rwu466ygjzgm56sd9c4at";
        in
        {
          creation_rules = [
            {
              key_groups = [
                {
                  age = [
                    azaleoid
                  ];
                }
              ];

              path_regex = "^src/azaleoid/etc/sops\.yaml$";
            }
            {
              key_groups = [
                {
                  age = [
                    bingshan
                  ];
                }
              ];

              path_regex = "^src/bingshan/etc/(sops\.yaml|fonts/.*\.(otf|ttf)\.sops)$";
            }
            {
              key_groups = [
                {
                  age = [
                    camellia
                  ];
                }
              ];

              path_regex = "^src/camellia/etc/sops\.yaml$";
            }
            {
              key_groups = [
                {
                  age = [
                    erythron
                  ];
                }
              ];

              path_regex = "^src/erythron/etc/sops\.yaml$";
            }
            {
              key_groups = [
                {
                  age = [
                    magnolia
                  ];
                }
              ];

              path_regex = "^src/magnolia/etc/sops\.yaml$";
            }
          ];
        };

      generator =
        data: (yaml { }).generate (baseNameOf path) data;

      packages = with pkgs; [
        age
        sops
        ssh-to-age
      ];

      path = ".sops.yaml";
    };

    treefmt = rec {
      data = {
        formatter = {
          emacs-lisp = {
            command = "elisp-format";

            includes = [
              "*.el"
            ];
          };

          markdown = {
            command = "mdformat";

            excludes = [
              ".codex/**/*.md"
            ];

            includes = [
              "*.md"
            ];

            options = [
              "--extensions=frontmatter"
              "--extensions=gfm"
              "--number"
              "--wrap=80"
            ];
          };

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

      generator =
        data: (toml { }).generate (baseNameOf path) data;

      packages =
        let
          mdformatWithPlugins = mdformat.withPlugins (
            ps: with ps; [
              mdformat-frontmatter
              mdformat-gfm
            ]
          );
        in
        with pkgs;
        [
          elisp-format
          mdformatWithPlugins
          nixfmt
          treefmt
        ];

      path = "treefmt.toml";
    };
  };
}
