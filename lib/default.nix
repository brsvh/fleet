{
  infix-lib,
  lib,
  ...
}:
let
  inherit (lib)
    foldl'
    makeExtensible
    recursiveUpdate
    ;

  projectRoot = ../.;
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
    importers = import' ./importers.nix;
    transformers = import' ./transformers.nix;

    __tests = foldl' recursiveUpdate { } [
      (importTest ../test/importers.nix)
      (importTest ../test/transformers.nix)
    ];
  }
)
