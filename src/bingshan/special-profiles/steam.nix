{
  home,
  pkgs,
  ...
}:
let
  inherit (pkgs)
    proton-ge-bin
    ;
in
{
  imports = [
    home.profiles.steam
  ];

  programs = {
    steam = {
      config = {
        apps = {
          "Counter-Strike 2" = {
            id = 730;
          };

          "Stellar Blade" = {
            compatTool = proton-ge-bin;
            id = 3489700;
          };
        };
      };
    };
  };
}
