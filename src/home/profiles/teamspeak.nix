{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    ;

  desktopEntry = pkgs.makeDesktopItem {
    categories = [
      "Audio"
      "AudioVideo"
      "Chat"
      "Network"
    ];

    comment = "TeamSpeak Voice Communication Client";
    desktopName = "TeamSpeak";
    exec = "${getExe pkgs.teamspeak6-client} %u";
    icon = "teamspeak6-client";

    mimeTypes = [
      "x-scheme-handler/ts3server"
      "x-scheme-handler/teamspeak"
    ];

    name = "com.teamspeak.teamspeak";
    startupNotify = false;
    startupWMClass = "TeamSpeak";
  };
in
{
  home = {
    packages = with pkgs; [
      teamspeak6-client
    ];
  };

  xdg = {
    dataFile = {
      # The client-generated launcher bypasses the Nix audio library wrapper.
      "applications/com.teamspeak.teamspeak.desktop" = {
        source = "${desktopEntry}/share/applications/com.teamspeak.teamspeak.desktop";
      };
    };
  };
}
