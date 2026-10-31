{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    elem
    filterAttrs
    mapAttrs
    mapAttrs'
    nameValuePair
    optionalAttrs
    removeAttrs
    ;

  system = "x86_64-linux";

  hosts = removeAttrs config.configurations.system [
    "global"
  ];

  targets = {
    global = {
      handler = "check/global";
      kind = "global";

      outputs =
        (removeAttrs self.checks.${system} [
          "deploy-activate"
          "deploy-schema"
        ])
        // {
          devshell = self.devShells.${system}.default;
          formatter = self.formatter.${system};
        };
    };
  }
  // mapAttrs' (
    name: _:
    nameValuePair "host-${name}" {
      inherit name;

      deploy = name != "magnolia";
      handler = "check/host/${name}";
      kind = "host";

      outputs = {
        deploy =
          self.deploy.nodes.${name}.profiles.system.path;
        system =
          self.nixosConfigurations.${name}.config.system.build.toplevel;
      }
      // inputs.deploy.lib.${system}.deployChecks {
        nodes = {
          ${name} = self.deploy.nodes.${name};
        };
      };
    }
  ) hosts
  // mapAttrs' (
    name: home:
    nameValuePair "user-${name}" {
      inherit name;

      handler = "check/user/${name}";
      kind = "user";

      outputs = {
        home = home.activationPackage;
      };
    }
  ) self.homeConfigurations;
in
{
  flake = {
    ci = {
      builds = mapAttrs (
        _: target: target.outputs
      ) targets;

      targets = mapAttrs (
        _: target: removeAttrs target [ "outputs" ]
      ) targets;
    };

    herculesCI =
      {
        branch ? null,
        primaryRepo ? { },
        ref ? null,
        rev ? null,
        ...
      }:
      let
        trustedBranch =
          elem branch [
            "main"
            "develop"
          ]
          && ref == "refs/heads/${branch}"
          && (primaryRepo.owner or null) == "brsvh"
          && (primaryRepo.name or null) == "fleet";
      in
      {
        ciSystems = [
          system
        ];

        onPush = optionalAttrs trustedBranch (
          {
            # Preserve the required status without a polling Effect.
            plan = {
              outputs = self.ci.builds;
            };
          }
          // mapAttrs' (
            _: target:
            nameValuePair target.handler {
              outputs = target.outputs;
            }
          ) targets
          // optionalAttrs (branch == "main") (
            mapAttrs'
              (
                _: target:
                nameValuePair "release/${target.name}" {
                  outputs = {
                    # Request approval only after the complete graph builds.
                    checks = self.ci.builds;

                    effects = {
                      release = import ./release.nix {
                        inherit
                          inputs
                          rev
                          self
                          system
                          ;

                        host = target.name;
                      };
                    };
                  };
                }
              )
              (
                filterAttrs (
                  _: target: target.kind == "host" && target.deploy
                ) targets
              )
          )
        );
      };
  };
}
