{
  bingshan,
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    getExe
    head
    ;

  email = head (
    filter (
      account: account.enable && account.primary
    ) (attrValues config.accounts.email.accounts)
  );

  passdir =
    config.programs.password-store.settings.PASSWORD_STORE_DIR;
in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.password-store
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
        credential = {
          helper = getExe pkgs.pass-git-helper;
        };

        "credential \"https://github.com\"" = {
          useHttpPath = true;
        };

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

  xdg = {
    configFile = {
      "pass-git-helper/git-pass-mapping.ini" = {
        text = ''
          [codeberg.org]
          target = codeberg.org/bingshan
          password_store_dir = ${passdir}
          username_extractor = static
          username = bingshan

          [github.com/brsvh/*]
          target = github.com/brsvh
          password_store_dir = ${passdir}
          username_extractor = static
          username = brsvh

          [github.com/YuanshengClaw/*]
          target = github.com/YuanshengClaw
          password_store_dir = ${passdir}
          username_extractor = static
          username = brsvh

          [*]
          target = ''${host}/''${username}
          password_store_dir = ${passdir}
          username_extractor = entry_name
        '';
      };
    };
  };
}
