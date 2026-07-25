{
  system,
  ...
}:
{
  imports = [
    system.profiles.openrgb
  ];

  boot = {
    kernelModules = [
      "i2c-i801"
    ];
  };
}
