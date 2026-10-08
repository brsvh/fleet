{
  nixpkgs,
  pkgs,
}:
let
  repository = "https://github.com/brsvh/chinese-fonts-overlay";

  probeScript = pkgs.writeShellScript "hercules-ci-worker-probe" ''
    ${pkgs.nix}/bin/nix --extra-experimental-features nix-command \
      config show --json | ${pkgs.jq}/bin/jq -r '
        .["allow-import-from-derivation"].value,
        .["max-jobs"].value
      '
    printf '%s\n' "$@"
    cat
    exit "''${TEST_WORKER_STATUS:-0}"
  '';

  probe =
    pkgs.runCommand "hercules-ci-worker-probe"
      {
        version = "0.10.8";
      }
      ''
        mkdir -p "$out/bin"
        ln -s ${probeScript} "$out/bin/hercules-ci-agent-worker"
        ln -s ${pkgs.coreutils}/bin/true "$out/bin/hercules-ci-nix-daemon"
      '';

  machine = nixpkgs.lib.nixosSystem {
    system = pkgs.stdenv.hostPlatform.system;

    modules = [
      ../src/system/modules/hercules-ci-worker.nix
      {
        nixpkgs = {
          inherit
            pkgs
            ;
        };

        services = {
          hercules-ci-agent = {
            enable = true;
            package = probe;

            noIFDRepositories = [
              repository
            ];
          };
        };

        system = {
          stateVersion = "26.05";
        };
      }
    ];
  };

  workerDirectory =
    machine.config.systemd.services.hercules-ci-agent.environment.hercules_ci_agent_bindir;
in
pkgs.runCommand "hercules-ci-worker-policy-check"
  {
    nativeBuildInputs = with pkgs; [
      diffutils
      gnugrep
    ];
  }
  ''
    export NIX_CONF_DIR="$TMPDIR/nix-conf"
    mkdir -p "$NIX_CONF_DIR"
    export NIX_USER_CONF_FILES=/dev/null
    export NIX_CONFIG="allow-import-from-derivation = true
    max-jobs = 7"
    workerPath=${workerDirectory}/hercules-ci-agent-worker

    grep -aFq hercules_ci_agent_bindir \
      ${pkgs.hercules-ci-agent}/libexec/hercules-ci-agent

    checkPolicy() {
      local expectedFlag="$1"
      shift
      printf '\0\377\npayload' | "$workerPath" "$@" > actual

      {
        printf '%s\n' "$expectedFlag" 7 "$@"
        printf '\0\377\npayload'
      } > expected

      cmp expected actual
    }

    checkPolicy false eval ${repository} revision
    checkPolicy false eval ${repository}/ revision
    checkPolicy true eval https://github.com/brsvh/emanote revision
    checkPolicy true eval https://github.com/brsvh/home-manager revision
    checkPolicy true eval ${repository}-extra revision
    checkPolicy true build ${repository} revision
    checkPolicy true effect ${repository} revision
    test -x ${workerDirectory}/hercules-ci-nix-daemon

    if "$workerPath" eval "" revision </dev/null > actual 2> missing; then
      echo 'An evaluation without repository metadata was accepted' >&2
      exit 1
    else
      test "$?" -eq 78
    fi

    if TEST_WORKER_STATUS=37 "$workerPath" build derivation \
      </dev/null > actual; then
      echo 'Worker exit status was lost' >&2
      exit 1
    else
      test "$?" -eq 37
    fi

    touch "$out"
  ''
