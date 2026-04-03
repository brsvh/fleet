{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.nix
  ];

  home = {
    packages = with pkgs; [
      cachix
    ];
  };
}
