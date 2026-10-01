{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    attrNames
    elem
    elemAt
    hasAttr
    map
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
      paths = [ "test/" ];
      outputs = removeAttrs self.checks.${system} [
        "deploy-activate"
        "deploy-schema"
      ];
    };
  }
  // mapAttrs' (
    name: host:
    nameValuePair "host-${name}" {
      inherit name;

      deploy = name != "magnolia";
      handler = "check/host/${name}";
      kind = "host";
      paths = [
        "src/${name}/"
        "src/system/"
        "src/home/"
      ]
      ++ map (user: "src/${user}/") (
        attrNames host.users
      );
      outputs = {
        system =
          self.nixosConfigurations.${name}.config.system.build.toplevel;
        deploy =
          self.deploy.nodes.${name}.profiles.system.path;
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
      paths = [
        "src/${name}/"
        "src/home/"
      ];
      outputs = {
        home = home.activationPackage;
      };
    }
  ) self.homeConfigurations;
in
{
  flake = {
    ci = {
      targets = mapAttrs (
        _: target: removeAttrs target [ "outputs" ]
      ) targets;
      builds = mapAttrs (
        _: target: target.outputs
      ) targets;
    };

    herculesCI =
      {
        branch ? null,
        primaryRepo ? { },
        ref ? null,
        rev ? null,
        tag ? null,
        ...
      }:
      let
        checkRequest =
          if tag == null then
            null
          else
            builtins.match "ci/check/(main|develop)/([a-z0-9-]+)/([0-9a-f]{40})/([0-9a-f-]{36})" tag;
        deployRequest =
          if tag == null then
            null
          else
            builtins.match "ci/deploy/([a-z0-9-]+)/([0-9a-f]{40})/([0-9]+)/([0-9]+)" tag;
        checkTarget = elemAt checkRequest 1;
        deployHost = elemAt deployRequest 0;
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
        ciSystems = [ system ];

        # Hercules accepts contributions from repository writers. This ref
        # filter limits our entry points; it is not the authorization boundary.
        onPush =
          if
            checkRequest != null
            && elemAt checkRequest 2 == rev
            && hasAttr checkTarget targets
          then
            {
              "${targets.${checkTarget}.handler}" = {
                outputs = targets.${checkTarget}.outputs // {
                  effects = {
                    finish = import ./finish.nix {
                      inherit
                        inputs
                        rev
                        system
                        tag
                        ;
                      branch = elemAt checkRequest 0;
                      target = targets.${checkTarget};
                    };
                  };
                };
              };
            }
          else if
            deployRequest != null
            && elemAt deployRequest 1 == rev
            && deployHost != "magnolia"
            && hasAttr deployHost hosts
          then
            {
              "deploy/${deployHost}" = {
                outputs = {
                  effects = {
                    deploy = import ./deploy.nix {
                      inherit
                        inputs
                        rev
                        self
                        system
                        ;
                      host = deployHost;
                      runId = elemAt deployRequest 2;
                      attempt = elemAt deployRequest 3;
                    };
                  };
                };
              };
            }
          else
            optionalAttrs trustedBranch {
              plan = {
                outputs = {
                  effects = {
                    plan = import ./plan.nix {
                      inherit
                        branch
                        inputs
                        rev
                        system
                        ;
                      targets = self.ci.targets;
                    };
                  };
                };
              };
            };
      };
  };
}
