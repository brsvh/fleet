{
  infix-lib,
  lib,
  ...
}:
let
  inherit (infix-lib)
    dirToAttrs
    dirsToAttrs
    ;

  inherit (lib)
    pipe
    ;
in
rec {
  /**
    Read a directory tree and apply transformations to the resulting attribute
    set.

    # Inputs

    `dir`
    : Directory path to read

    `txs`
    : List of transformations to apply to the directory attribute set

    # Type

    ```
    collect :: Path -> [Attrs -> Attrs] -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.importers.collect` usage example

    ```nix
    collect ./modules [ filterNix removeExtension ]
    => {
      __path = ./modules;
      default = ./modules/default.nix;
    }
    ```

    :::
  */
  collect = dir: txs: pipe (dirToAttrs dir) txs;

  /**
    Read and merge multiple directory trees, then apply transformations to the
    resulting attribute set.

    # Inputs

    `dirs`
    : Directory paths to read and merge

    `txs`
    : List of transformations to apply to the merged attribute set

    # Type

    ```
    collect' :: [Path] -> [Attrs -> Attrs] -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.importers.collect'` usage example

    ```nix
    collect' [ ./modules ./overrides ] [ filterNix removeExtension ]
    => {
      base = ./modules/base.nix;
      default = ./overrides/default.nix;
    }
    ```

    :::
  */
  collect' = dirs: txs: pipe (dirsToAttrs dirs) txs;
}
