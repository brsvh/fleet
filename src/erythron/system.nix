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
    disko.nixosModules.disko
    erythron.disko
  ];

  hardware = {
    facter = {
      reportPath = erythron.etc.facter;
    };
  };

  system = {
    stateVersion = "26.11";
  };
}
