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
            checks = {
              inherit (self.checks.x86_64-linux)
                test
                ;
            };

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
