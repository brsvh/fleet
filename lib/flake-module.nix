{
  infix-lib,
  lib,
  projectRoot,
  ...
}:
let
  fleet-lib = import (projectRoot + /lib) {
    inherit
      infix-lib
      lib
      projectRoot
      ;
  };
in
{
  _module = {
    args = {
      inherit
        fleet-lib
        ;
    };
  };

  flake = {
    lib = fleet-lib;
  };
}
