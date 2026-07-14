{
  infix-lib,
  lib,
  projectRoot,
  ...
}:
let
  inherit (lib)
    foldl'
    makeExtensible
    recursiveUpdate
    ;
in
makeExtensible (
  final:
  let
    import' =
      file:
      import file {
        inherit
          infix-lib
          lib
          ;

        fleet-lib = final;
      };

    importTest =
      file:
      import file {
        inherit
          infix-lib
          lib
          projectRoot
          ;

        fleet-lib = final;
      };
  in
  {
    importers = import' (
      projectRoot + /lib/importers.nix
    );

    transformers = import' (
      projectRoot + /lib/transformers.nix
    );

    __tests = foldl' recursiveUpdate { } [
      (importTest (projectRoot + /test/importers.nix))
      (importTest (
        projectRoot + /test/transformers.nix
      ))
    ];
  }
)
