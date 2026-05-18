{
  camellia,
  inputs,
  modulesPath,
  ...
}:
let
  inherit (inputs)
    disko
    ;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    camellia.disko
    disko.nixosModules.disko
  ];

  hardware = {
    facter = {
      reportPath = camellia.etc.facter;
    };
  };

  system = {
    stateVersion = "26.05";
  };
}
