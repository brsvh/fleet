{
  system,
  ...
}:
{
  imports = [
    system.profiles.qemu
  ];

  boot = {
    binfmt = {
      addEmulatedSystemsToNixSandbox = true;

      emulatedSystems = [
        "aarch64-linux"
        "loongarch64-linux"
        "riscv64-linux"
      ];
    };
  };
}
