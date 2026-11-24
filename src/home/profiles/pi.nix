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
    home.profiles.git
  ];

  programs = {
    git = {
      ignores = [
        "/.pi"
      ];
    };

    pi-coding-agent = {
      enable = mkDefault true;
      mutableSettings = mkDefault true;
    };
  };
}
