{
  config,
  inputs,
  ...
}:
let
  inherit (inputs)
    sops
    ;
in
{
  imports = [
    sops.homeManagerModules.sops
  ];

  sops = {
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    };
  };
}
