{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    ;

  inherit (lib)
    mkDefault
    ;
in
{
  nix = {
    registry = {
      nixpkgs = {
        flake = nixpkgs;
      };
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = mkDefault true;
    };
  };
}
