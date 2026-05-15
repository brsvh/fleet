{
  infix-lib,
  lib,
  ...
}:
let
  inherit (infix-lib)
    mapAttrsRecursive'
    mapAttrsRecursiveCond'
    stemOf
    ;

  inherit (lib)
    elem
    filterAttrs
    filterAttrsRecursive
    hasSuffix
    isAttrs
    last
    nameValuePair
    toCamelCase
    ;
in
{
  /**
    Rename attribute keys recursively to camel case while preserving internal
    path metadata.

    # Inputs

    `attrs`
    : Attribute set to transform recursively

    # Type

    ```
    camelify :: Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.camelify` usage example

    ```nix
    camelify {
      __path = ./modules;
      "system-config.nix" = ./modules/system-config.nix;
    }
    => {
      __path = ./modules;
      systemConfig = ./modules/system-config.nix;
    }
    ```

    :::
  */
  camelify = mapAttrsRecursive' (
    path: value:
    let
      basename = last path;
    in
    nameValuePair (
      if basename == "__path" then
        "__path"
      else
        (toCamelCase (stemOf basename))
    ) value
  );

  /**
    Remove selected top-level attributes from an attribute set.

    # Inputs

    `dirs`
    : Attribute names to remove from the top level

    `attrs`
    : Attribute set to filter

    # Type

    ```
    excludeTopLevelDirs :: [String] -> Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.excludeTopLevelDirs` usage example

    ```nix
    excludeTopLevelDirs [ "private" ] {
      keep = "root";
      private = "root";
    }
    => {
      keep = "root";
    }
    ```

    :::
  */
  excludeTopLevelDirs =
    dirs: filterAttrs (name: _: !(elem name dirs));

  /**
    Keep Nix files, attribute sets, and internal path metadata in a recursive
    attribute tree.

    # Inputs

    `attrs`
    : Attribute set to filter recursively

    # Type

    ```
    filterNix :: Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.filterNix` usage example

    ```nix
    filterNix {
      __path = ./modules;
      module = ./modules/module.nix;
      note = ./modules/note.md;
    }
    => {
      __path = ./modules;
      module = ./modules/module.nix;
    }
    ```

    :::
  */
  filterNix = filterAttrsRecursive (
    name: value:
    if (isAttrs value) || (name == "__path") then
      true
    else
      hasSuffix ".nix" (toString value)
  );

  /**
    Replace recursive attribute values that contain `default` with their
    default value and remove file extensions from leaf names.

    # Inputs

    `attrs`
    : Attribute set to transform recursively

    # Type

    ```
    liftDefault :: Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.liftDefault` usage example

    ```nix
    liftDefault {
      "module.nix" = {
        default = "module";
        ignored = "extra";
      };
    }
    => {
      module = "module";
    }
    ```

    :::
  */
  liftDefault =
    mapAttrsRecursiveCond'
      (v: !(isAttrs v && v ? default))
      (
        path: v:
        nameValuePair (stemOf (last path)) (
          if isAttrs v && v ? default then v.default else v
        )
      );

  /**
    Remove file extensions from recursive attribute names while preserving
    internal path metadata.

    # Inputs

    `attrs`
    : Attribute set to transform recursively

    # Type

    ```
    removeExtension :: Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.removeExtension` usage example

    ```nix
    removeExtension {
      __path = ./modules;
      "default.nix" = ./modules/default.nix;
    }
    => {
      __path = ./modules;
      default = ./modules/default.nix;
    }
    ```

    :::
  */
  removeExtension = mapAttrsRecursive' (
    path: value:
    let
      basename = last path;
    in
    nameValuePair (
      if basename == "__path" then
        "__path"
      else
        (stemOf basename)
    ) value
  );

  /**
    Remove internal path metadata from a recursive attribute tree.

    # Inputs

    `attrs`
    : Attribute set to filter recursively

    # Type

    ```
    removeInternalPath :: Attrs -> Attrs
    ```

    # Examples
    :::{.example}
    ## `lib.transformers.removeInternalPath` usage example

    ```nix
    removeInternalPath {
      __path = ./modules;
      default = ./modules/default.nix;
    }
    => {
      default = ./modules/default.nix;
    }
    ```

    :::
  */
  removeInternalPath = filterAttrsRecursive (
    name: _: name != "__path"
  );
}
