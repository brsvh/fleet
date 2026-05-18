{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.home)
    username
    ;

  inherit (lib)
    mkDefault
    ;

  email =
    config.accounts.email.accounts.${username};
in
{
  imports = [
    home.profiles.xdg
  ];

  accounts = {
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
      enable = email.offlineimap.enable;
    };

    mu = {
      enable = email.mu.enable;
    };

    msmtp = {
      enable = email.msmtp.enable;
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
