{
  fleet-lib,
  projectRoot,
  ...
}:
let
  inherit (fleet-lib.importers)
    collect
    collect'
    ;

  inherit (fleet-lib.transformers)
    filterNix
    removeExtension
    ;

  fixtureDir =
    projectRoot + /test/fixtures/importers;

  leftDir = fixtureDir + /left;

  rightDir = fixtureDir + /right;
in
{
  importers = {
    collect = {
      testCollectsDirectoryAndAppliesTransformers = {
        expr = collect leftDir [
          filterNix
          removeExtension
        ];

        expected = {
          __path = leftDir;

          "left-only" = leftDir + /left-only.nix;

          nested = {
            __path = leftDir + /nested;

            left = leftDir + /nested/left.nix;
            shared = leftDir + /nested/shared.nix;
          };

          shared = leftDir + /shared.nix;
        };
      };
    };

    collect' = {
      testMergesDirectoriesAndAppliesTransformers = {
        expr =
          collect'
            [
              leftDir
              rightDir
            ]
            [
              filterNix
              removeExtension
            ];

        expected = {
          "left-only" = leftDir + /left-only.nix;

          nested = {
            left = leftDir + /nested/left.nix;
            right = rightDir + /nested/right.nix;
            shared = rightDir + /nested/shared.nix;
          };

          "right-only" = rightDir + /right-only.nix;
          shared = rightDir + /shared.nix;
        };
      };
    };
  };
}
