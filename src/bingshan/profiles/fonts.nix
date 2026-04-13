{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.fonts
  ];

  fonts = {
    fontconfig = {
      configFile = {
        embolden = {
          enable = true;
          priority = 10;

          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Synthetic emboldening for fonts that do not have bold face available</description>

              <match target="font">
                <test name="weight" compare="less_eq">
                  <const>medium</const>
                </test>

                <test target="pattern" name="weight" compare="more">
                  <const>medium</const>
                </test>

                <edit name="embolden" mode="assign">
                  <bool>true</bool>
                </edit>

                <edit name="weight" mode="assign">
                  <const>bold</const>
                </edit>
              </match>

            </fontconfig>
          '';
        };

        latin = {
          enable = true;
          priority = 60;

          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Set preferable fonts for Latin</description>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Andale Mono</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Arial</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Comic Sans MS</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Georgia</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Impact</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Trebuchet MS</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Verdana</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Courier New</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Times New Roman</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Tahoma</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Webdings</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Albany AMT</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Thorndale AMT</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Cumberland AMT</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Andale Sans</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Andy MT</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Bell MT</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq">
                  <string>Monotype Sorts</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
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

        nonlatin = {
          enable = true;
          priority = 65;

          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Set preferable fonts for Non-Latin</description>

              <match target="font">
                <test target="pattern" name="lang" compare="contains">
                  <string>zh</string>
                </test>
                <edit name="spacing" mode="assign">
                  <const>proportional</const>
                </edit>
                <edit name="globaladvance" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test target="pattern" name="lang" compare="contains">
                  <string>ja</string>
                </test>
                <edit name="spacing" mode="assign">
                  <const>proportional</const>
                </edit>
                <edit name="globaladvance" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="font">
                <test target="pattern" name="lang" compare="contains">
                  <string>ko</string>
                </test>
                <edit name="spacing" mode="assign">
                  <const>proportional</const>
                </edit>
                <edit name="globaladvance" mode="assign">
                  <bool>false</bool>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>SimSun</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>SimSun-18030</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL ShanHeiSun Uni</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL New Sung</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>MingLiU</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="eq" qual="any">
                  <string>PMingLiU</string>
                </test>
                <edit binding="strong" mode="prepend" name="family">
                  <string>Tahoma</string>
                  <string>Arial</string>
                  <string>Verdana</string>
                  <string>DejaVu Sans</string>
                  <string>Bitstream Vera Sans</string>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL ShanHeiSun Uni</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL New Sung</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>SimSun</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>NSimSun</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>MingLiU</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>PMingLiU</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>12</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>12</double>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>宋体</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>新宋体</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>SimSun</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>NSimSun</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>宋体-18030</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>新宋体-18030</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>SimSun-18030</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>NSimSun-18030</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL ShanHeiSun Uni</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>AR PL New Sung</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>MingLiU</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

              <match target="font">
                <test name="family" compare="eq" qual="any">
                  <string>PMingLiU</string>
                </test>
                <test name="pixelsize" compare="less_eq">
                  <double>16</double>
                </test>
                <edit name="hinting" mode="assign">
                  <bool>true</bool>
                </edit>
                <edit name="autohint" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="antialias" mode="assign">
                  <bool>false</bool>
                </edit>
                <edit name="hintstyle" mode="assign">
                  <const>hintslight</const>
                </edit>
              </match>

            </fontconfig>
          '';
        };
      };

      defaultFonts = {
        emoji = [
          "Twitter Color Emoji"
        ];

        monospace = [
          "Courier New"
          "Cumberland AMT"
          "Nimbus Mono L"
          "Andale Mono"
          "DejaVu Sans Mono"
          "Bitstream Vera Sans Mono"
          "Luxi Mono"
          "FreeMono"
          "NSimSun"
          "NSimSun-18030"
          "PMingLiU"
          "WenQuanYi Bitmap Song"
          "AR PL ShanHeiSun Uni"
          "AR PL New Sung"
          "FZSongTi"
          "FZMingTiB"
          "AR PL SungtiL GB"
          "AR PL Mingti2L Big5"
          "Kochi Gothic"
          "UnDotum"
          "Baekmuk Gulim"
          "Baekmuk Dotum"
          "HanyiSong"
          "ZYSong18030"
        ];

        sansSerif = [
          "Arial"
          "Albany AMT"
          "Nimbus Sans L"
          "Verdana"
          "DejaVu Sans"
          "Bitstream Vera Sans"
          "Luxi Sans"
          "FreeSans"
          "Helvetica"
          "SimSun"
          "SimSun-18030"
          "MingLiU"
          "WenQuanYi Bitmap Song"
          "AR PL ShanHeiSun Uni"
          "AR PL New Sung"
          "FZSongTi"
          "FZMingTiB"
          "AR PL SungtiL GB"
          "AR PL Mingti2L Big5"
          "Kochi Gothic"
          "UnDotum"
          "Baekmuk Gulim"
          "Baekmuk Dotum"
        ];

        serif = [
          "Times New Roman"
          "Thorndale AMT"
          "Nimbus Roman No9 L"
          "DejaVu Serif"
          "Bitstream Vera Serif"
          "Luxi Serif"
          "Likhan"
          "FreeSerif"
          "Times"
          "SimSun"
          "SimSun-18030"
          "MingLiU"
          "WenQuanYi Bitmap Song"
          "AR PL ShanHeiSun Uni"
          "AR PL New Sung"
          "FZSongTi"
          "FZMingTiB"
          "AR PL SungtiL GB"
          "AR PL Mingti2L Big5"
          "Kochi Mincho"
          "UnBatang"
          "Baekmuk Batang"
          "HanyiSong"
          "ZYSong18030"
        ];
      };
    };
  };

  home = {
    packages = with pkgs; [
      twitter-color-emoji
      windows-fonts
    ];
  };
}
