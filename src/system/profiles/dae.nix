{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  services = {
    dae = {
      enable = mkDefault true;

      package = mkDefault (
        pkgs.dae.overrideAttrs (
          _: prevAttrs: {
            MAX_MATCH_SET_LEN = "4096";

            # Preserve the BPF limit when Nixpkgs overrides CFLAGS.
            postPatch = (prevAttrs.postPatch or "") + ''
              substituteInPlace Makefile \
                --replace-fail \
                  'CFLAGS := -DMAX_MATCH_SET_LEN=$(MAX_MATCH_SET_LEN) $(CFLAGS)' \
                  'override CFLAGS := -DMAX_MATCH_SET_LEN=$(MAX_MATCH_SET_LEN) $(CFLAGS)'
            '';
          }
        )
      );
    };
  };
}
