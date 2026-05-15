{
  inputs,
  self,
  ...
}:
let
  inherit (inputs)
    infix
    nixpkgs
    ;
in
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (pkgs)
        writeShellApplication
        writeText
        ;

      tests = writeText "tests.nix" ''
        let
          lib = import ${nixpkgs}/lib;

          infix-lib = import ${infix}/lib {
            inherit
              lib
              ;
          };
        in
        (import ${self}/lib {
          inherit
            infix-lib
            lib
            ;
        }).__tests
      '';

      run-test = writeShellApplication {
        name = "run-test";

        runtimeInputs = with pkgs; [
          nix-unit
        ];

        text = ''
          if [ -n "''${NIX_BUILD_TOP:-}" ]; then
            homeDir="$(realpath .)"
            export HOME="$homeDir"
          else
            tmpdir="$(mktemp -d)"
            trap 'rm -rf "$tmpdir" 2>/dev/null || true' EXIT
            export HOME="$tmpdir"
          fi

          mkdir -p "$HOME/gcroots"
          mkdir -p "$HOME/nix-conf"

          unset NIX_CONFIG
          export NIX_CONF_DIR="$HOME/nix-conf"
          export XDG_CACHE_HOME="$HOME/.cache"

          nix-unit \
            --eval-store "$HOME" \
            --gc-roots-dir "$HOME/gcroots" \
            --show-trace \
            ${tests}
        '';
      };

      test = pkgs.runCommand "test" { } ''
        ${run-test}/bin/run-test

        mkdir -p "$out/bin"
        ln -s ${run-test}/bin/run-test "$out/bin/test"
      '';
    in
    {
      apps = {
        test = {
          meta = {
            description = "Run the nix-unit test suite.";
          };

          type = "app";
          program = "${config.packages.test}/bin/test";
        };
      };

      checks = {
        inherit
          test
          ;
      };

      packages = {
        inherit
          test
          ;
      };
    };
}
