{
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mapAttrs
    ;
in
{
  flake = {
    herculesCI = {
      ciSystems = [
        "x86_64-linux"
      ];

      onPush = {
        default = {
          outputs = {
            checks = self.checks.x86_64-linux;

            deploy = mapAttrs (
              _: node:
              mapAttrs (_: profile: profile.path) node.profiles
            ) self.deploy.nodes;

            nixos = mapAttrs (
              _: configuration:
              configuration.config.system.build.toplevel
            ) self.nixosConfigurations;
          };
        };
      };
    };
  };
}
