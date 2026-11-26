{
  inputs,
  magnolia,
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
    magnolia.disko
  ];

  hardware = {
    facter = {
      reportPath = magnolia.etc.facter;
    };
  };

  system = {
    stateVersion = "26.05";
  };

  time = {
    timeZone = "Asia/Shanghai";
  };
}
