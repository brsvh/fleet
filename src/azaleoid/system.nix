{
  azaleoid,
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
    azaleoid.disko
    disko.nixosModules.disko
  ];

  hardware = {
    facter = {
      reportPath = azaleoid.etc.facter;
    };
  };

  system = {
    stateVersion = "25.11";
  };

  time = {
    timeZone = "Asia/Shanghai";
  };
}
