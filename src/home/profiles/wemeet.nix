{
  home,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.modules.wemeet
  ];

  programs = {
    wemeet = {
      enable = mkDefault true;
    };
  };

  xdg = {
    desktopEntries = {
      wemeetapp = {
        categories = [
          "AudioVideo"
        ];

        exec = "wemeet-xwayland %u";
        icon = "wemeet";

        mimeType = [
          "x-scheme-handler/wemeet"
        ];

        name = "WemeetApp";

        settings = {
          "Name[zh_CN]" = "腾讯会议";
        };
      };
    };
  };
}
