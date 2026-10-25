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
    home.modules.accounts
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
    khal = {
      enable = mkDefault true;

      package = mkDefault (
        pkgs.khal.overrideAttrs (_: {
          # The Sphinx hook reads only the first element of a Bash array.
          sphinxBuilders = "html man";
        })
      );
    };

    khard = {
      enable = mkDefault true;
    };

    msmtp = {
      enable = mkDefault true;
    };

    mu = {
      enable = mkDefault true;
    };

    offlineimap = {
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
