{
  bingshan,
  config,
  home,
  ...
}:
{
  imports = [
    bingshan.profiles.password-store
    home.profiles.accounts
  ];

  accounts =
    let
      bingshan = {
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
      };

      brsvh = {
        inherit (bingshan.mail)
          host
          passwordCommand
          userName
          ;
      };

      changbingshan = rec {
        host = "mail.cstnet.cn";
        passwordCommand = "pass show ${host}/${userName}";
        userName = "changbingshan@iscas.ac.cn";
      };
    in
    {
      calendar = {
        accounts = {
          bingshan = {
            primary = true;
            primaryCollection = "personal";

            khal = {
              enable = true;
              type = "discover";
            };

            local = {
              path = "${config.accounts.calendar.basePath}/${bingshan.cloud.host}";
            };

            remote = {
              inherit (bingshan.cloud)
                passwordCommand
                userName
                ;

              type = "caldav";
              url = "https://${bingshan.cloud.host}/remote.php/dav/calendars/${bingshan.cloud.userName}/";
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
          bingshan = {
            emacs = {
              addressbooks = {
                contacts = {
                  default = true;
                };
              };
            };

            khard = {
              enable = true;
              type = "discover";
            };

            local = {
              path = "${config.accounts.contact.basePath}/${bingshan.cloud.host}";
            };

            remote = {
              inherit (bingshan.cloud)
                passwordCommand
                userName
                ;

              type = "carddav";
              url = "https://${bingshan.cloud.host}/remote.php/dav/addressbooks/users/${bingshan.cloud.userName}/";
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
          bingshan = rec {
            inherit (bingshan.mail)
              passwordCommand
              userName
              ;

            address = userName;

            folders = {
              drafts = "Drafts";
              inbox = "INBOX";
              junk = "Junk";
              sent = "Sent";
              trash = "Trash";
            };

            gpg = {
              key = "D6E9ED4504C41AD2DA16F39631E62A2FC33802BA";
              signByDefault = true;
            };

            imap = {
              host = bingshan.mail.host;
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
              host = bingshan.mail.host;
              port = 465;

              tls = {
                enable = true;
              };
            };
          };

          brsvh = rec {
            inherit (brsvh)
              passwordCommand
              userName
              ;

            address = "bsc@brsvh.org";

            aliases = [
              "bot@brsvh.org"
              "open@brsvh.org"
              "register@brsvh.org"
              "steam@brsvh.org"
            ];

            folders = {
              drafts = "Drafts";
              inbox = "INBOX";
              junk = "Junk";
              sent = "Sent";
              trash = "Trash";
            };

            gpg = {
              key = "7B740DB9F2AC6D3B226BC53078D74502D92E0218";
              signByDefault = true;
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

            primary = false;
            realName = "Burgess Chang";

            signature = {
              text = ''
                ${realName}
                Nanjing, China
                Pronoun: He/Him/His
                GPG: 7B74 0DB9 F2AC 6D3B 226B  C530 78D7 4502 D92E 0218
              '';
            };

            smtp = {
              host = brsvh.host;
              port = 465;

              tls = {
                enable = true;
              };
            };
          };

          changbingshan = rec {
            inherit (changbingshan)
              passwordCommand
              userName
              ;

            address = userName;

            folders = {
              drafts = "Drafts";
              inbox = "INBOX";
              junk = "Junk E-mail";
              sent = "Sent Items";
              trash = "Trash";
            };

            gpg = {
              key = "F178C7173550EA893D32DD07324AE98654C0D86C";
              signByDefault = true;
            };

            imap = {
              host = changbingshan.host;
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
              host = changbingshan.host;
              port = 465;

              tls = {
                enable = true;
              };
            };
          };
        };
      };
    };

  programs = {
    khal = {
      locale = {
        dateformat = "%Y-%m-%d";
        datetimeformat = "%Y-%m-%d %H:%M";
        default_timezone = "Asia/Shanghai";
        local_timezone = "Asia/Shanghai";
        longdateformat = "%Y-%m-%d %a";
        longdatetimeformat = "%Y-%m-%d %a %H:%M";
        timeformat = "%H:%M";
      };
    };
  };
}
