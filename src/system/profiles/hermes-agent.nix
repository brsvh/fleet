{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    hermes-agent
    ;

  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkDefault
    ;

  normalUsers = filterAttrs (
    _: v: v.enable && v.isNormalUser
  ) config.users.users;

  normalUsersList = mapAttrsToList (
    _: value: value.name
  ) normalUsers;
in
{
  imports = [
    hermes-agent.nixosModules.default
  ];

  services = {
    hermes-agent = {
      addToSystemPackages = mkDefault true;

      container = {
        backend = mkDefault "docker";
        enable = mkDefault true;
        hostUsers = normalUsersList;
      };
    };
  };

  users = {
    groups = {
      hermes = {
        members = normalUsersList;
      };
    };
  };
}
