{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.firefox
  ];

  home = {
    packages = with pkgs; [
      firefox-devtools-mcp
    ];
  };

  programs = {
    firefox = {
      policies = {
        DontCheckDefaultBrowser = true;
      };
    };
  };
}
