{
  lib,
  system,
  ...
}:
{
  imports = [
    system.profiles.docker
    system.profiles.nixos-container
    system.profiles.podman
  ];

  virtualisation = {
    oci-containers = {
      backend = "podman";
    };
  };
}
