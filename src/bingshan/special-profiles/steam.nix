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
          "1091500" = {
            args = [
              "--launcher-skip"
            ];

            compatTool = "proton_experimental";
            id = 1091500;
            name = "Cyberpunk 2077";
          };

          "3489700" = {
            compatTool = proton-ge-bin;
            id = 3489700;
            name = "Stellar Blade";
          };

          "377160" = {
            compatTool = "proton_experimental";

            env = {
              # Keep vanilla physics timing stable on high-refresh displays.
              DXVK_FRAME_RATE = 60;
            };

            id = 377160;
            name = "Fallout 4";
          };

          "412830" = {
            # GE provides additional video playback fixes for WMV cutscenes.
            compatTool = proton-ge-bin;
            id = 412830;
            name = "STEINS;GATE";
          };

          "730" = {
            id = 730;
            name = "Counter-Strike 2";
          };
        };
      };
    };
  };
}
