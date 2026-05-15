{
  fleet-lib,
  ...
}:
let
  inherit (fleet-lib.transformers)
    camelify
    excludeTopLevelDirs
    filterNix
    liftDefault
    removeExtension
    removeInternalPath
    ;
in
{
  transformers = {
    camelify = {
      testCamelifiesNamesAndKeepsPathMetadata = {
        expr = camelify {
          __path = "/src/root";

          "feature-module.nix" = "root";

          "nested-dir" = {
            __path = "/src/root/nested-dir";

            "child-module.nix" = "child";
          };
        };

        expected = {
          __path = "/src/root";

          featureModule = "root";

          nestedDir = {
            __path = "/src/root/nested-dir";

            childModule = "child";
          };
        };
      };
    };

    excludeTopLevelDirs = {
      testExcludesOnlyTopLevelDirectories = {
        expr =
          excludeTopLevelDirs
            [
              "private"
            ]
            {
              keep = "root";

              nested = {
                private = "nested";
              };

              private = "root";
            };

        expected = {
          keep = "root";

          nested = {
            private = "nested";
          };
        };
      };
    };

    filterNix = {
      testKeepsNixFilesAndPathMetadata = {
        expr = filterNix {
          __path = "/src/root";

          "module.nix" = "/src/root/module.nix";
          "note.txt" = "/src/root/note.txt";

          nested = {
            "child.nix" = "/src/root/nested/child.nix";
            "note.md" = "/src/root/nested/note.md";
          };
        };

        expected = {
          __path = "/src/root";

          "module.nix" = "/src/root/module.nix";

          nested = {
            "child.nix" = "/src/root/nested/child.nix";
          };
        };
      };
    };

    liftDefault = {
      testLiftsDefaultValuesAndRemovesExtensions = {
        expr = liftDefault {
          group = {
            "child.nix" = {
              default = "child";
              extra = "ignored";
            };

            plain = "plain";
          };

          "root.nix" = {
            default = "root";
            passthrough = false;
          };
        };

        expected = {
          group = {
            child = "child";
            plain = "plain";
          };

          root = "root";
        };
      };
    };

    removeExtension = {
      testRemovesExtensionsAndKeepsPathMetadata = {
        expr = removeExtension {
          __path = "/src/root";

          ".env" = "env";
          "module.nix" = "root";

          nested = {
            "child.nix" = "child";
          };
        };

        expected = {
          __path = "/src/root";

          ".env" = "env";
          module = "root";

          nested = {
            child = "child";
          };
        };
      };
    };

    removeInternalPath = {
      testRemovesPathMetadataRecursively = {
        expr = removeInternalPath {
          __path = "/src/root";

          module = {
            __path = "/src/root/module";

            file = "module.nix";
          };
        };

        expected = {
          module = {
            file = "module.nix";
          };
        };
      };
    };
  };
}
