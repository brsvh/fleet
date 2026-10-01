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
      kind = "host";
      deploy = name != "magnolia";
      inherit name;
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
      kind = "user";
      inherit name;
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
        tag ? null,
        rev ? null,
        ...
      }:
      let
        request =
          if tag == null then
            null
          else
            builtins.match "ci/(check|deploy)/([a-z0-9-]+)/([0-9a-f]{40})/([0-9]+)/([0-9]+)" tag;
        valid =
          request != null && elemAt request 2 == rev;
        action = elemAt request 0;
        target = elemAt request 1;
      in
      {
        ciSystems = [ system ];
        # Only workflow-selected tags enqueue work. Ordinary pushes still
        # register the configuration, but do not build the whole fleet.
        onPush = optionalAttrs valid (
          if
            action == "check" && hasAttr target targets
          then
            {
              "check-${target}" = {
                outputs = targets.${target}.outputs;
              };
            }
          else if
            action == "deploy"
            && target != "magnolia"
            && hasAttr target hosts
          then
            {
              "deploy-${target}" = {
                outputs = {
                  effects = {
                    deploy = import ./deploy.nix {
                      inherit
                        inputs
                        rev
                        self
                        system
                        ;
                      host = target;
                      runId = elemAt request 3;
                      attempt = elemAt request 4;
                    };
                  };
                };
              };
            }
          else
            { }
        );
      };
  };
}
