{
  system,
  ...
}:
{
  imports = [
    system.profiles.swap
  ];

  zramSwap = {
    writebackDevice = "/dev/disk/by-partlabel/disk-azaleoid-swap";
  };
}
