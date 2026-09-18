{
  config,
  home,
  pkgs,
  ...
}:
let
  chromePackage =
    config.programs.chromium.finalPackage;

  chrome-devtools = pkgs.chrome-devtools.override {
    browser = chromePackage;
  };

  chromiumDesktop = "google-chrome.desktop";

  chromiumAssociation = {
    "application/atom+xml" = [ chromiumDesktop ];
    "application/pdf" = [ chromiumDesktop ];
    "application/rss+xml" = [ chromiumDesktop ];
    "application/xhtml+xml" = [ chromiumDesktop ];
    "application/xml" = [ chromiumDesktop ];
    "image/svg+xml" = [ chromiumDesktop ];
    "text/html" = [ chromiumDesktop ];
    "text/xml" = [ chromiumDesktop ];
    "x-scheme-handler/http" = [ chromiumDesktop ];
    "x-scheme-handler/https" = [ chromiumDesktop ];
  };
in
{
  imports = [
    home.profiles.chromium
  ];

  home = {
    packages = [
      chrome-devtools
    ];
  };

  programs = {
    chromium = {
      commandLineArgs = [
        "--enable-features=VerticalTabs"
      ];
    };
  };

  xdg = {
    mimeApps = {
      defaultApplicationPackages = [
        chromePackage
      ];

      defaultApplications = chromiumAssociation;
    };
  };
}
