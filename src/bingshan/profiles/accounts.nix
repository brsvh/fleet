{
  bingshan,
  config,
  home,
  ...
}:
let
  mail = rec {
    host = "mail.bingshan.org";
    passwordCommand = "pass show ${host}/${userName}";
    userName = "chang@bingshan.org";
  };

  cloud = rec {
    host = "cloud.bingshan.org";

    passwordCommand = [
      "pass"
      "show"
      "${host}/${userName}"
    ];

    userName = "bingshan";
  };
in
{
  imports = [
    bingshan.profiles.password-store
    home.profiles.accounts
  ];

  accounts = {
    calendar = {
      accounts = {
        cloud = {
          khal = {
            enable = true;
            type = "discover";
          };

          local = {
            path = "${config.accounts.calendar.basePath}/${cloud.host}";
          };

          remote = {
            inherit (cloud)
              passwordCommand
              userName
              ;

            type = "caldav";
            url = "https://${cloud.host}/remote.php/dav/calendars/${cloud.userName}/";
          };

          vdirsyncer = {
            enable = true;

            collections = [
              "from a"
              "from b"
            ];
          };
        };

        holidays_in_china = {
          khal = {
            enable = true;
            readOnly = true;
          };

          local = {
            path = "${config.accounts.calendar.basePath}/Calendar/holiday@group.v.calendar.google.com/en.china.official";
          };

          remote = {
            type = "http";
            url = "https://calendar.google.com/calendar/ical/en.china%23holiday%40group.v.calendar.google.com/public/basic.ics";
          };

          vdirsyncer = {
            conflictResolution = "remote wins";
            enable = true;
            partialSync = "revert";
          };
        };

        holidays_in_united_states = {
          khal = {
            enable = true;
            readOnly = true;
          };

          local = {
            path = "${config.accounts.calendar.basePath}/Calendar/holiday@group.v.calendar.google.com/en.usa.official";
          };

          remote = {
            type = "http";
            url = "https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics";
          };

          vdirsyncer = {
            conflictResolution = "remote wins";
            enable = true;
            partialSync = "revert";
          };
        };

        riscv_technical_meetings = {
          khal = {
            enable = true;
            readOnly = true;
          };

          local = {
            path = "${config.accounts.calendar.basePath}/Calendar/tech.meetings@riscv.org";
          };

          remote = {
            type = "http";
            url = "https://calendar.google.com/calendar/ical/tech.meetings%40riscv.org/public/basic.ics";
          };

          vdirsyncer = {
            conflictResolution = "remote wins";
            enable = true;
            partialSync = "revert";
          };
        };
      };
    };

    contact = {
      accounts = {
        cloud = {
          emacs = {
            default = true;
            enable = true;
          };

          khard = {
            enable = true;
            type = "discover";
          };

          local = {
            path = "${config.accounts.contact.basePath}/${cloud.host}";
          };

          remote = {
            inherit (cloud)
              passwordCommand
              userName
              ;

            type = "carddav";
            url = "https://${cloud.host}/remote.php/dav/addressbooks/users/${cloud.userName}/";
          };

          vdirsyncer = {
            enable = true;

            collections = [
              "from a"
              "from b"
            ];
          };
        };
      };
    };

    email = {
      accounts = {
        "${mail.userName}" = rec {
          inherit (mail)
            passwordCommand
            userName
            ;

          address = userName;

          aliases = [
            "bsc@brsvh.org"
            "bot@brsvh.org"
            "open@brsvh.org"
            "register@brsvh.org"
            "steam@brsvh.org"
          ];

          gpg = {
            key = "D6E9ED4504C41AD2DA16F39631E62A2FC33802BA";
            signByDefault = true;
          };

          imap = {
            host = mail.host;
            port = 993;

            tls = {
              enable = true;
            };
          };

          msmtp = {
            enable = true;
          };

          mu = {
            enable = true;
          };

          offlineimap = {
            enable = true;

            extraConfig = {
              account = {
                autorefresh = 20;
              };

              local = {
                sync_deletes = true;
              };
            };
          };

          primary = true;
          realName = "Bingshan Chang";

          signature = {
            text = ''
              ${realName}
              Nanjing, China
              Pronoun: He/Him/His
              GPG: D6E9 ED45 04C4 1AD2 DA16  F396 31E6 2A2F C338 02BA
            '';
          };

          smtp = {
            host = mail.host;
            port = 465;

            tls = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
