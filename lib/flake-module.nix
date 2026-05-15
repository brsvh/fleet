{
  infix-lib,
  lib,
  ...
}:
let
  fleet-lib = import ./. {
    inherit
      infix-lib
      lib
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
