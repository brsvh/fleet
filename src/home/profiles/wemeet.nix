{
  home,
  lib,
  pkgs,
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

      package = mkDefault (
        pkgs.wemeet.overrideAttrs (prevAttrs: {
          postFixup = (prevAttrs.postFixup or "") + ''
            wrapProgram "$out/bin/wemeet" \
              --set-default QT_IM_MODULE fcitx
            wrapProgram "$out/bin/wemeet-xwayland" \
              --set-default QT_IM_MODULE fcitx
          '';
        })
      );
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
