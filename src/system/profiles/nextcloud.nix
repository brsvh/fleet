{
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.profiles.nginx
  ];

  services = {
    nextcloud = {
      appstoreEnable = mkDefault false;

      config = {
        dbtype = mkDefault "pgsql";

        objectstore = {
          s3 = {
            enable = mkDefault true;
          };
        };
      };

      configureRedis = mkDefault true;

      database = {
        createLocally = mkDefault true;
      };

      enable = mkDefault true;

      extraApps = {
        inherit (pkgs.nextcloud33Packages.apps)
          calendar
          collectives
          contacts
          deck
          drawio
          forms
          mail
          music
          news
          notes
          onlyoffice
          polls
          tasks
          whiteboard
          ;
      };

      https = mkDefault true;
      package = pkgs.nextcloud33;
    };
  };
}
