{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    home.modules.offlineimap
    home.profiles.xdg
  ];

  accounts = {
    calendar = {
      basePath = mkDefault "${config.xdg.dataHome}/Calendars";
    };

    contact = {
      basePath = mkDefault "${config.xdg.dataHome}/Contacts";
    };

    email = {
      maildirBasePath = mkDefault "${config.xdg.dataHome}/Mail";
    };
  };

  home = {
    packages = with pkgs; [
      mailutils
    ];

    sessionVariables = {
      MAILDIR = "${config.accounts.email.maildirBasePath
      }";
    };
  };

  programs = {
    offlineimap = {
      enable = mkDefault true;
    };

    mu = {
      enable = mkDefault true;
    };

    msmtp = {
      enable = mkDefault true;
    };

    khal = {
      enable = mkDefault true;
    };

    khard = {
      enable = mkDefault true;
    };

    vdirsyncer = {
      enable = mkDefault true;
    };
  };

  services = {
    offlineimap = {
      enable = mkDefault true;
      frequency = mkDefault "*:0/5";
    };

    vdirsyncer = {
      enable = mkDefault true;
      frequency = mkDefault "*:0/5";
    };
  };
}
