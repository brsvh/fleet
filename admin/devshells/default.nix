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
in
{
  commands = with pkgs; [
    {
      category = "deployment";
      name = "deploy";
      package = "deploy-rs";
    }
    {
      category = "development";
      help = "Commit staged changes using Codex and the commit skill";
      name = "commit";

      package = writeShellScriptBin "commit" ''
        exec ${getExe codex} exec "$@" '$commit'
      '';
    }
    {
      category = "tools";
      package = git;
    }
    {
      category = "tools";
      package = treefmt;
    }
  ];

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
          "admin/agents/AGENTS.md"
        ];

        project_doc_max_bytes = 32768;
        review_model = "gpt-5.5";
        sandbox_mode = "workspace-write";
        service_tier = "fast";
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
            if gitDir="$(${getExe git} -C "$PRJ_ROOT" rev-parse --absolute-git-dir 2>/dev/null)"; then
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

              gitDir="$(${getExe git} -C "$PRJ_ROOT" rev-parse --absolute-git-dir 2>/dev/null || true)"

              if [ -n "$gitDir" ]; then
                if [ -e "$gitDir/MERGE_HEAD" ] \
                  || [ -d "$gitDir/rebase-apply" ] \
                  || [ -d "$gitDir/rebase-merge" ]; then
                  exit 0
                fi

                ref="$(${getExe git} -C "$PRJ_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

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
        subdir = "admin/agents/skills";
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
