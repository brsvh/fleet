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
          "730" = {
            id = 730;
            name = "Counter-Strike 2";
          };

          "3489700" = {
            compatTool = proton-ge-bin;
            id = 3489700;
            name = "Stellar Blade";
          };
        };
      };
    };
  };
}
