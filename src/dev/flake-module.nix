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
            codex = {
              data = {
                approval_policy = "on-request";
                model = "gpt-5.4";
                model_provider = "openai";
                model_reasoning_effort = "medium";
                model_reasoning_summary = "auto";
                model_verbosity = "medium";
                personality = "pragmatic";
                plan_mode_reasoning_effort = "high";
                project_doc_max_bytes = 32768;
                review_model = "gpt-5.4";
                sandbox_mode = "workspace-write";
                web_search = "cached";

                agents = {
                  job_max_runtime_seconds = 1800;
                  max_depth = 1;
                  max_threads = 2;
                };

                mcp_servers = {
                  github = {
                    command = "github-mcp-server";
                    required = false;
                    startup_timeout_sec = 20;
                    tool_timeout_sec = 120;
                  };

                  nixos = {
                    command = "mcp-nixos";
                    required = false;
                    startup_timeout_sec = 20;
                    tool_timeout_sec = 120;
                  };
                };

                sandbox_workspace_write = {
                  exclude_slash_tmp = false;
                  exclude_tmpdir_env_var = false;
                  network_access = false;
                  writable_roots = [ ];
                };

                shell_environment_policy = {
                  "inherit" = "all";

                  exclude = [ ];

                  experimental_use_profile = false;
                  ignore_default_excludes = false;

                  include_only = [ ];

                  set = { };
                };
              };

              format = "toml";
              output = ".codex/config.toml";

              packages = with pkgs; [
                codex
                github-mcp-server
                mcp-nixos
              ];
            };

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

                "*.md" = {
                  indent_size = 2;
                  indent_style = "space";
                  max_line_length = 80;
                  trim_trailing_whitespace = false;
                };

                "*.nix" = {
                  indent_size = 2;
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

              format = "yaml";
              output = ".sops.yaml";

              packages = with pkgs; [
                age
                sops
                ssh-to-age
              ];
            };

            treefmt = {
              data = {
                formatter = {
                  markdown = {
                    command = "mdformat";

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

              format = "toml";
              output = "treefmt.toml";

              packages =
                let
                  mdformatWithPlugins = pkgs.mdformat.withPlugins (
                    ps: with ps; [
                      mdformat-frontmatter
                    ]
                  );
                in
                with pkgs;
                [
                  mdformatWithPlugins
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
