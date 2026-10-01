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
    match
    nameValuePair
    optionalAttrs
    pipe
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

      outputs = removeAttrs self.checks.${system} [
        "deploy-activate"
        "deploy-schema"
      ];

      paths = [
        "test/"
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

      paths = [
        "src/${name}/"
        "src/system/"
        "src/home/"
      ]
      ++ pipe host.users [
        attrNames
        (map (user: "src/${user}/"))
      ];
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

      paths = [
        "src/${name}/"
        "src/home/"
      ];
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
        tag ? null,
        ...
      }:
      let
        checkRequest =
          if tag == null then
            null
          else
            match "ci/check/(main|develop)/([a-z0-9-]+)/([0-9a-f]{40})/([0-9a-f-]{36})" tag;

        deployRequest =
          if tag == null then
            null
          else
            match "ci/deploy/([a-z0-9-]+)/([0-9a-f]{40})/([0-9]+)/([0-9]+)" tag;

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
        ciSystems = [
          system
        ];

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

                      attempt = elemAt deployRequest 3;
                      host = deployHost;
                      runId = elemAt deployRequest 2;
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
