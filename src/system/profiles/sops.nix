{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    sops
    ;

  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    sops.nixosModules.sops
  ];

  sops = {
    age = {
      keyFile = mkDefault "/var/lib/sops/age/keys.txt";
    };
  };
}
