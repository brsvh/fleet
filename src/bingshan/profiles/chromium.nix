{
  home,
  ...
}:
{
  imports = [
    home.profiles.chromium
  ];

  programs = {
    chromium = {
      commandLineArgs = [
        "--enable-features=VerticalTabs"
      ];
    };
  };
}
