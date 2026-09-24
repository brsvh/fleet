{
  config,
  pkgs,
  system,
  ...
}:
let
  inherit (pkgs)
    writeShellApplication
    ;

  publish = writeShellApplication {
    name = "nix-cache-publish";

    runtimeInputs = [
      config.nix.package
    ];

    text = ''
      if [ "$#" -eq 0 ]; then
        printf 'Usage: nix-cache-publish STORE_PATH_OR_RESULT...\n' >&2
        exit 2
      fi

      exec nix copy \
        --option netrc-file ${config.sops.secrets.nix-cache-upload-netrc.path} \
        --to 'https://cache.bingshan.org?compression=zstd' \
        "$@"
    '';
  };
in
{
  imports = [
    system.profiles.nix
  ];

  environment = {
    systemPackages = [
      publish
    ];
  };

  nix = {
    settings = {
      cores = 8;
      max-jobs = 2;

      substituters = [
        "https://cache.bingshan.org?priority=35"
      ];

      trusted-public-keys = [
        "cache.bingshan.org-1:HqcG/vJ7jeSLU48jV4yg8Ot+rUPP2v0vIAAnDEqVSvk="
      ];
    };

    sshServe = {
      enable = true;

      keys = [
        ''restrict,from="100.64.0.3" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6utBNc5//VxGVx4LDk88ZckW0v0qqhF+4p9i6ga3oI azaleoid-to-magnolia-nix-builder''
      ];

      trusted = true;
    };
  };

  sops = {
    secrets = {
      nix-cache-upload-netrc = {
        key = "nix-cache/upload-netrc";
        owner = "bingshan";
      };
    };
  };
}
