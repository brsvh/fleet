{
  erythron,
  inputs,
  ...
}:
let
  inherit (inputs)
    disko
    ;
in
{
  imports = [
    erythron.disko
    disko.nixosModules.disko
  ];

  hardware = {
    facter = {
      reportPath = erythron.etc.facter;
    };
  };

  system = {
    stateVersion = "26.05";
  };
}
