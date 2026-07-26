{
  home,
  ...
}:
{
  imports = [
    home.profiles.steam
  ];

  programs = {
    steam = {
      config = {
        apps = {
          "Counter-Strike 2" = {
            id = 730;
          };
        };
      };
    };
  };
}
