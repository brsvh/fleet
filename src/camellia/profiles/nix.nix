{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkForce
    ;
in
{
  imports = [
    system.profiles.nix
  ];

  nix = {
    settings = {
      # Override the base @wheel trust on the public server.
      trusted-users = mkForce [
        "root"
      ];
    };
  };
}
