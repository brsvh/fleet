{
  bingshan,
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    readDir
    ;

  inherit (lib)
    filterAttrs
    getExe'
    hasSuffix
    mapAttrs'
    mkForce
    nameValuePair
    removeSuffix
    ;

  inherit (pkgs)
    fontconfig
    ;
in
{
  imports = [
    bingshan.profiles.sops
    home.profiles.fonts
  ];

  fonts = {
    fontconfig = {
      configFile = {
        chinese-families = {
          enable = true;
          priority = 60;

          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Prefer Chinese families</description>

              <match target="pattern">
                <test name="lang" compare="contains">
                  <string>zh-cn</string>
                </test>
                <test name="family" compare="eq">
                  <string>sans-serif</string>
                </test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Microsoft YaHei UI</string>
                  <string>Microsoft YaHei</string>
                  <string>Segoe UI Variable Text</string>
                  <string>Segoe UI</string>
                  <string>Segoe UI Emoji</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="lang" compare="contains">
                  <string>zh-tw</string>
                </test>
                <test name="family" compare="eq">
                  <string>sans-serif</string>
                </test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Microsoft JhengHei UI</string>
                  <string>Microsoft JhengHei</string>
                  <string>Segoe UI Variable Text</string>
                  <string>Segoe UI</string>
                  <string>Segoe UI Emoji</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="lang" compare="contains">
                  <string>zh-hk</string>
                </test>
                <test name="family" compare="eq">
                  <string>sans-serif</string>
                </test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Microsoft JhengHei UI</string>
                  <string>Microsoft JhengHei</string>
                  <string>Segoe UI Variable Text</string>
                  <string>Segoe UI</string>
                  <string>Segoe UI Emoji</string>
                </edit>
              </match>
            </fontconfig>
          '';
        };

        metric-unaliases = {
          enable = true;
          priority = 30;

          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Unset substitutions for similar/metric-compatible families</description>

              <alias binding="same">
                <family>Helvetica</family>
                <accept>
                  <family>Arial</family>
                </accept>
              </alias>
              <alias binding="same">
                <family>Times</family>
                <accept>
                  <family>Times New Roman</family>
                </accept>
              </alias>
              <alias binding="same">
                <family>Courier</family>
                <accept>
                  <family>Courier New</family>
                </accept>
              </alias>

            </fontconfig>
          '';
        };
      };

      defaultFonts = {
        emoji = [
          "Segoe UI Emoji"
        ];

        monospace = [
          "Triplicate A Code"
          "Consolas"
          "Cascadia Mono"
          "Courier New"
          "NSimSun"
          "Segoe UI Emoji"
        ];

        sansSerif = [
          "Segoe UI Variable"
          "Segoe UI"
          "Microsoft YaHei UI"
          "Microsoft YaHei"
          "Segoe UI Emoji"
        ];

        serif = [
          "Georgia"
          "Times New Roman"
          "SimSun"
          "PMingLiU"
        ];
      };

      subpixelRendering = mkForce "rgb";
    };
  };

  home = {
    packages = with pkgs; [
      cascadia-code
      windows-fonts
    ];

    sessionVariables = {
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };
  };

  sops = {
    secrets =
      let
        directory = bingshan.etc.fonts.mbtype.__path;

        files = filterAttrs (
          name: type:
          type == "regular" && hasSuffix ".otf.sops" name
        ) (readDir directory);
      in
      mapAttrs' (
        name: _:
        let
          filename = removeSuffix ".sops" name;
        in
        nameValuePair "fonts/${filename}" {
          format = "binary";
          path = "${config.xdg.dataHome}/fonts/mbtype/${filename}";
          sopsFile = directory + "/${name}";
        }
      ) files;
  };

  systemd = {
    user = {
      services = {
        sops-nix = {
          Service = {
            ExecStartPost = ''
              ${getExe' fontconfig "fc-cache"} -f ${config.xdg.dataHome}/fonts/mbtype
            '';
          };
        };
      };
    };
  };
}
