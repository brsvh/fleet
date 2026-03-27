{
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  nix = {
    gc = {
      automatic = mkDefault true;
      dates = mkDefault "weekly";
      options = mkDefault "--delete-older-than 4w";
      persistent = mkDefault true;
    };

    optimise = {
      automatic = mkDefault true;
      persistent = mkDefault true;
    };

    settings = {
      allowed-users = [
        "@users"
      ];

      auto-optimise-store = true;
      builders-use-substitutes = true;

      experimental-features = [
        "auto-allocate-uids"
        "ca-derivations"
        "cgroups"
        "fetch-closure"
        "flakes"
        "nix-command"
        "pipe-operators"
      ];

      fallback = true;

      keep-build-log = true;
      keep-derivations = true;
      keep-env-derivations = true;
      keep-outputs = true;
      log-lines = 100;
      sandbox = true;

      trusted-users = [
        "@wheel"
        "root"
      ];

      use-xdg-base-directories = true;
    };
  };

  programs = {
    nix-ld = {
      enable = mkDefault true;
    };
  };
}
