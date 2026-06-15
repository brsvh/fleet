{
  bingshan,
  config,
  home,
  lib,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    head
    ;

  email = head (
    filter (
      account: account.enable && account.primary
    ) (attrValues config.accounts.email.accounts)
  );
in
{
  imports = [
    bingshan.profiles.accounts
    home.profiles.git
  ];

  programs = {
    git = {
      ignores = [
        "/.tmp"
      ];

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
