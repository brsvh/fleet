{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.global
  ];

  programs = {
    global = {
      package = pkgs.global.overrideAttrs (
        finalAttrs: prevAttrs: {
          NIX_CFLAGS_COMPILE =
            (prevAttrs.NIX_CFLAGS_COMPILE or "")
            + " -Wno-error=incompatible-pointer-types";
        }
      );
    };
  };
}
