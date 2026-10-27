{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    ;

  inputMethod = config.i18n.inputMethod;
in
{
  imports = [
    home.modules.wemeet
  ];

  programs = {
    wemeet = {
      enable = mkDefault true;

      package =
        mkIf
          (
            inputMethod.enable && inputMethod.type == "fcitx5"
          )
          (
            mkDefault (
              pkgs.wemeet.overrideAttrs (prevAttrs: {
                postFixup = (prevAttrs.postFixup or "") + ''
                  wrapProgram "$out/bin/wemeet" \
                    --set-default QT_IM_MODULE fcitx
                  wrapProgram "$out/bin/wemeet-xwayland" \
                    --set-default QT_IM_MODULE fcitx
                '';
              })
            )
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
