{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.cargo
  ];

  home = {
    packages = with pkgs; [
      rustc
    ];
  };
}
