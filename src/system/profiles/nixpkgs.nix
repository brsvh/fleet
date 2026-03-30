{
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
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
}
