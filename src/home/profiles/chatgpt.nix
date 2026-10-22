{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    optionals
    ;

  chatgpt = pkgs.llm-agents.chatgpt.override {
    chatgpt-unwrapped =
      pkgs.llm-agents.chatgpt.unwrapped.overrideAttrs
        (prevAttrs: {
          # The remote-control device-key module links against TPM2-TSS.
          buildInputs =
            (prevAttrs.buildInputs or [ ])
            ++ optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.tpm2-tss
            ];
        });
  };
in
{
  home = {
    packages = with pkgs; [
      bubblewrap
      chatgpt
    ];
  };
}
