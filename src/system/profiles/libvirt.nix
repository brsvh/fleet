{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  environment = {
    systemPackages = with pkgs; [
      OVMFFull
    ];
  };

  users = {
    groups = {
      kvm = {
        members = normalUsersList;
      };

      libvirtd = {
        members = normalUsersList;
      };
    };
  };

  virtualisation = {
    libvirtd = {
      enable = mkDefault true;
    };
  };
}
