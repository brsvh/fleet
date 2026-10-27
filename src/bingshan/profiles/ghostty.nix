{
  bingshan,
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    elemAt
    ;

  first = list: elemAt list 0;

  fonts = config.fonts.fontconfig.defaultFonts;

  monospace = first fonts.monospace;
in
{
  imports = [
    bingshan.profiles.fonts
    home.profiles.ghostty
  ];

  home = {
    packages = with pkgs; [
      lxgw-wenkai
      lxgwPackages.neo-zhisong
      lxgwPackages.zhenkai
    ];
  };

  programs = {
    ghostty = {
      settings = {
        cursor-style = "block";

        font-family = [
          monospace
          "LXGW Neo ZhiSong"
        ];

        font-family-bold = [
          monospace
          "LXGW Neo ZhiSong"
        ];

        font-family-bold-italic = [
          monospace
          "LXGW ZhenKai GB"
        ];

        font-family-italic = [
          monospace
          "LXGW WenKai"
        ];

        font-size = config.gtk.font.size;

        # Keep Chinese emphasis upright and native Latin italics intact.
        font-synthetic-style = "no-italic,no-bold-italic";

        shell-integration-features = "no-cursor,ssh-env,ssh-terminfo,sudo,title";
        theme = "Modus Operandi Tinted";
      };
    };
  };
}
