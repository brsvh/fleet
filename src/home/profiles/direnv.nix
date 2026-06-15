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
    direnv = {
      enable = mkDefault true;

      nix-direnv = {
        enable = mkDefault true;
      };
    };

    git = {
      ignores = [
        "/.direnv"
      ];
    };
  };
}
