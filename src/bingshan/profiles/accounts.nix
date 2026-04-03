{
  config,
  ...
}:
let
  inherit (config.home)
    username
    ;
in
{
  accounts = {
    email = {
      accounts = {
        ${username} = rec {
          address = "chang@bingshan.org";

          gpg = {
            key = "D6E9ED4504C41AD2DA16F39631E62A2FC33802BA";
            signByDefault = true;
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

          userName = address;
        };
      };
    };
  };
}
