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
    vdirsyncer = {
      enable = mkDefault true;
      frequency = mkDefault "*:0/5";
    };
  };

  systemd = {
    user = {
      services = {
        offlineimap = {
          Service = {
            ExecStart = "${config.programs.offlineimap.package}/bin/offlineimap -u basic -o";
            Type = "oneshot";
          };

          Unit = {
            Description = "OfflineIMAP sync";
          };
        };
      };

      timers = {
        offlineimap = {
          Install = {
            WantedBy = [
              "timers.target"
            ];
          };

          Timer = {
            OnCalendar = "*:0/5";
            Unit = "offlineimap.service";
          };

          Unit = {
            Description = "OfflineIMAP sync";
          };
        };
      };
    };
  };
}
