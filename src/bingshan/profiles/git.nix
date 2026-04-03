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

  email =
    config.accounts.email.accounts.${username};
in
{
  imports = [
    bingshan.profiles.accounts
    home.profiles.git
  ];

  programs = {
    git = {
      signing = {
        inherit (email.gpg)
          key
          signByDefault
          ;
      };

      settings = {
        user = {
          email = email.address;
          name = email.realName;
        };
      };
    };

    git-cliff = {
      enable = true;
    };
  };
}
