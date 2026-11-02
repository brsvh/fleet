{
  host,
  inputs,
  rev,
  self,
  system,
}:
let
  inherit (inputs.nixpkgs.lib)
    fileset
    hashString
    toCamelCase
    toJSON
    ;

  pkgs = inputs.nixpkgs.legacyPackages.${system};
  effects = inputs.hercules-ci-effects.lib.withPkgs pkgs;
  node = self.deploy.nodes.${host};

  deployment = import ./deploy.nix {
    inherit
      host
      node
      pkgs
      ;
  };

  deployPackage =
    inputs.deploy.packages.${system}.default;

  scripts = fileset.toSource {
    root = ./.;

    fileset = fileset.unions [
      ./deployment.mjs
      ./hercules.mjs
      ./http.mjs
    ];
  };

  systemPath =
    toString
      self.nixosConfigurations.${host}.config.system.build.toplevel;
  deployPath = toString node.profiles.system.path;

  fingerprint = hashString "sha256" (toJSON {
    inherit node systemPath;

    command = toString deployment;
    deploy = toString deployPackage;
  });

  request =
    pkgs.writeText "deployment-request.json"
      (toJSON {
        inherit
          deployPath
          fingerprint
          host
          systemPath
          ;

        requestId = hashString "sha256" "${host}\n${rev}\n${fingerprint}";
        revision = rev;
        schemaVersion = 1;
      });
in
effects.mkEffect {
  NIX_CONFIG = ''
    extra-experimental-features = nix-command flakes
  '';

  # Keep sharing the lock with deployment jobs from older revisions.
  effectScript = ''
    hci lock run --name fleet-release-${host} -- \
      node ${scripts}/deployment.mjs ${request} ${deployment}
  '';

  inputs = with pkgs; [
    coreutils
    deployPackage
    hci
    jq
    nix
    nodejs
    openssh
  ];

  name = toCamelCase "deploy-${host}";

  requiredSystemFeatures = [
    "deploy"
  ];

  secretsMap = {
    git = {
      type = "GitToken";
    };

    ssh = "deploy-ssh";
  };
}
