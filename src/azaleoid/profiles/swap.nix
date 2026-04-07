{
  system,
  ...
}:
{
  imports = [
    system.profiles.swap
  ];

  zramSwap = {
    writebackDevice = "/dev/nvme0n1p3";
  };
}
