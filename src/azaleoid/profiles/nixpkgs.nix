{
  system,
  ...
}:
{
  imports = [
    system.profiles.nixpkgs
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
