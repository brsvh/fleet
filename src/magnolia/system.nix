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
    magnolia.disko
    disko.nixosModules.disko
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
