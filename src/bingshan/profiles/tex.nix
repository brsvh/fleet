{
  bingshan,
  config,
  home,
  pkgs,
  ...
}:
{
  imports = [
    bingshan.profiles.fonts
    home.profiles.tex
  ];

  fonts = {
    fontconfig = {
      configFile = {
        texlive = {
          enable = true;
          priority = 10;

          # Emacs supplies its own Fontconfig file to child processes.
          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <dir>${config.programs.texlive.package.fonts}</dir>
            </fontconfig>
          '';
        };
      };
    };
  };

  home = {
    packages = with pkgs; [
      texlab
    ];
  };

  programs = {
    tex-fmt = {
      enable = true;

      settings = {
        format-tables = false;
        tabchar = "space";
        tabsize = 2;
        wrap = false;
      };
    };

    texlive = {
      packageSet = pkgs.texliveFull;
    };
  };

  xdg = {
    configFile = {
      "latexmk/latexmkrc" = {
        text = ''
          $pdf_mode = 5;
          $xelatex = 'xelatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
        '';
      };
    };
  };
}
