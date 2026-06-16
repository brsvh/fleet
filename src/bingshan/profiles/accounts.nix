{
  bingshan,
  config,
  home,
  ...
}:
let
  personalCloud = rec {
    host = "cloud.bingshan.org";

    passwordCommand = [
      "pass"
      "show"
      "${host}/${userName}"
    ];

    userName = "bingshan";
  };

  personalEmail = rec {
    host = "mail.bingshan.org";
    passwordCommand = "pass show ${host}/${userName}";
    userName = "chang@bingshan.org";
  };

  workEmail = rec {
    host = "mail.cstnet.cn";
    passwordCommand = "pass show ${host}/${userName}";
    userName = "changbingshan@iscas.ac.cn";
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
        personal = {
          khal = {
            enable = true;
            type = "discover";
          };

          local = {
            path = "${config.accounts.calendar.basePath}/${personalCloud.host}";
          };

          remote = {
            inherit (personalCloud)
              passwordCommand
              userName
              ;

            type = "caldav";
            url = "https://${personalCloud.host}/remote.php/dav/calendars/${personalCloud.userName}/";
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
        personal = {
          emacs = {
            default = true;
            enable = true;
          };

          khard = {
            enable = true;
            type = "discover";
          };

          local = {
            path = "${config.accounts.contact.basePath}/${personalCloud.host}";
          };

          remote = {
            inherit (personalCloud)
              passwordCommand
              userName
              ;

            type = "carddav";
            url = "https://${personalCloud.host}/remote.php/dav/addressbooks/users/${personalCloud.userName}/";
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
        personal = rec {
          inherit (personalEmail)
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
            host = personalEmail.host;
            port = 993;

            tls = {
              enable = true;
            };
          };

          maildir = {
            path = userName;
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
            host = personalEmail.host;
            port = 465;

            tls = {
              enable = true;
            };
          };
        };

        work = rec {
          inherit (workEmail)
            passwordCommand
            userName
            ;

          address = userName;

          gpg = {
            key = "F178C7173550EA893D32DD07324AE98654C0D86C";
            signByDefault = true;
          };

          imap = {
            host = workEmail.host;
            port = 993;

            tls = {
              enable = true;
            };
          };

          maildir = {
            path = userName;
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

          primary = false;
          realName = "Bingshan Chang";

          signature = {
            text = ''
              ${realName}
              Institute of Software, Chinese Academy of Sciences
              Nanjing, China
              Pronoun: He/Him/His
              GPG: F178 C717 3550 EA89 3D32  DD07 324A E986 54C0 D86C
            '';
          };

          smtp = {
            host = workEmail.host;
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
