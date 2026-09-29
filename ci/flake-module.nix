{
  self,
  ...
}:
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

            nixos = {
              magnolia =
                self.nixosConfigurations.magnolia.config.system.build.toplevel;
            };
          };
        };
      };
    };
  };
}
