{
  bingshan,
  config,
  home,
  ...
}:
let
  inherit (config.home)
    username
    ;

  account =
    config.accounts.email.accounts.${username};
in
{
  imports = [
    bingshan.profiles.account
    home.profiles.git
  ];

  programs = {
    git = {
      signing = {
        inherit (account.gpg)
          key
          signByDefault
          ;
      };

      settings = {
        user = {
          email = account.address;
          name = account.realName;
        };
      };
    };

    git-cliff = {
      enable = true;
    };
  };
}
