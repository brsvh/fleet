{
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    elem
    optionals
    ;
in
{
  imports = [
    home.profiles.codex
  ];

  programs = {
    codex = {
      package =
        pkgs.llm-agents.codex.overrideAttrs
          (prevAttrs: {
            # New aws-lc omits the OpenSSL pkg-config shim.
            # Remove once llm-agents includes PR #12320.
            buildInputs =
              (prevAttrs.buildInputs or [ ])
              ++ optionals (
                pkgs.stdenv.hostPlatform.isLinux
                && !(elem "openssl" (
                  pkgs.aws-lc.meta.pkgConfigModules or [ ]
                ))
              ) [ pkgs.openssl ];
          });
    };
  };
}
