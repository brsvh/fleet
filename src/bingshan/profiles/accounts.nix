{
  config,
  home,
  ...
}:
let
  inherit (config.home)
    username
    ;

  email =
    config.accounts.email.accounts.${username};
in
{
  imports = [
    home.profiles.accounts
  ];

  accounts = {
    email = {
      accounts = {
        ${username} = rec {
          address = "chang@bingshan.org";

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
            host = "mail.bingshan.org";
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

          passwordCommand = "pass show ${imap.host}/${userName}";

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
            host = "mail.bingshan.org";
            port = 465;

            tls = {
              enable = true;
            };
          };

          userName = address;
        };
      };
    };
  };
}
