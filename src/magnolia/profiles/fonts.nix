{
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkForce
    ;

  ibm-plex-math = pkgs.ibm-plex.override {
    families = [ "math" ];
  };

  ibm-plex-mono = pkgs.ibm-plex.override {
    families = [ "mono" ];
  };

  ibm-plex-sans = pkgs.ibm-plex.override {
    families = [ "sans" ];
  };

  ibm-plex-serif = pkgs.ibm-plex.override {
    families = [ "serif" ];
  };
in
{
  imports = [
    system.profiles.fonts
  ];

  fonts = {
    enableDefaultPackages = mkForce false;

    fontconfig = {
      defaultFonts = {
        emoji = mkForce [
          "Twitter Color Emoji"
        ];

        monospace = mkForce [
          "IBM Plex Mono"
        ];

        sansSerif = mkForce [
          "IBM Plex Sans"
        ];

        serif = mkForce [
          "IBM Plex Serif"
        ];
      };

      subpixel = {
        lcdfilter = mkForce "default";
        rgba = mkForce "rgb";
      };
    };

    packages = mkForce (
      with pkgs;
      [
        ibm-plex-math
        ibm-plex-mono
        ibm-plex-sans
        ibm-plex-serif
        twitter-color-emoji
      ]
    );
  };
}
