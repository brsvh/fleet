{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (inputs)
    bingshan-skills
    openai-skills
    ;

  inherit (lib)
    attrNames
    baseNameOf
    concatStringsSep
    getExe
    map
    optional
    pipe
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
in
{
  files = {
    codex = rec {
      data = {
        approval_policy = "on-request";
        model = "gpt-5.5";
        model_reasoning_effort = "xhigh";
        model_reasoning_summary = "auto";
        model_verbosity = "high";
        personality = "pragmatic";
        plan_mode_reasoning_effort = "xhigh";

        project_doc_fallback_filenames = [
          "dev/agents/AGENTS.md"
        ];

        project_doc_max_bytes = 32768;
        review_model = "gpt-5.5";
        sandbox_mode = "workspace-write";
        web_search = "cached";

        agents = {
          job_max_runtime_seconds = 1800;
          max_depth = 1;
          max_threads = 2;
        };

        sandbox_workspace_write = {
          exclude_slash_tmp = false;
          exclude_tmpdir_env_var = false;
          network_access = false;
        };

        shell_environment_policy = {
          "inherit" = "all";

          experimental_use_profile = false;
          ignore_default_excludes = false;
        };
      };

      generator =
        data: (toml { }).generate (baseNameOf path) data;

      packages = with pkgs; [
        codex
      ];

      path = ".codex/config.toml";
    };

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

    lefthook = rec {
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

      deps = [
        "treefmt"
      ];

      generator =
        data: (yaml { }).generate (baseNameOf path) data;

      hook =
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
        pipe data [
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
            ''ln -sf "${mkScript stage}" "$PRJ_ROOT/.git/hooks/${stage}"''
          ))
          (
            stages:
            optional (stages != [ ]) ''
              mkdir -p "$PRJ_ROOT/.git/hooks"
            ''
            ++ stages
          )
          (concatStringsSep "\n")
        ];

      packages = with pkgs; [
        lefthook
      ];

      path = "lefthook.yml";
    };

    sops = rec {
      data =
        let
          azaleoid = "age16dqp5jglesqrl3g683dv7zkahuaq6h3e9w88je70cgd0rhj53edq2a00xm";

          bingshan = "age170frnnagdmfajd686ahxztn7suxn7890jsqeh4fgpugltrnm4cpqmkdd0h";

          erythron = "age1svqryg3zmt67c6229sfem69hhe8aqup7v82r9req0vmrhd4mk9ks6gh4an";
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
                    erythron
                  ];
                }
              ];

              path_regex = "^src/erythron/etc/sops\.yaml$";
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

  skills = {
    skills = {
      cli-creator = {
        from = "openai";
        path = "cli-creator";
      };

      fleet-commit = {
        from = "fleet";
        path = "commit";
      };

      nix-gnu-style-commit = {
        from = "bingshan";
        path = "nix-gnu-style-commit";
      };

      nix-code-refactor = {
        from = "bingshan";

        packages = with pkgs; [
          nixfmt
        ];

        path = "nix-code-refactor";
      };
    };

    sources = {
      bingshan = {
        idPrefix = "bingshan";
        path = "${bingshan-skills}";
        subdir = "skills";
      };

      fleet = {
        idPrefix = "fleet";
        path = "${self}";
        subdir = "dev/agents/skills";
      };

      openai = {
        idPrefix = "openai";
        path = "${openai-skills}";
        subdir = "skills/.curated";
      };
    };

    targets = {
      codex = {
        dest = ".codex/skills";
        structure = "symlink-tree";
        enable = true;
      };
    };
  };
}
