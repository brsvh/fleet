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
    pipe
    ;

  email = pipe config.accounts.email.accounts [
    attrValues
    (filter (
      account: account.enable && account.primary
    ))
    head
  ];

  iniFormat = pkgs.formats.ini { };

  passwordStoreDir =
    config.programs.password-store.settings.PASSWORD_STORE_DIR;

  mappingEntry = target: username: {
    inherit
      target
      username
      ;

    password_store_dir = passwordStoreDir;
    username_extractor = "static";
  };
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

      signing = {
        inherit (email.gpg)
          key
          signByDefault
          ;
      };
    };

    git-cliff = {
      enable = true;
    };
  };

  xdg = {
    configFile = {
      "pass-git-helper/git-pass-mapping.ini" = {
        source =
          iniFormat.generate "git-pass-mapping.ini"
            {
              "codeberg.org" =
                mappingEntry "codeberg.org/bingshan" "bingshan";

              "github.com/YuanshengClaw/*" =
                mappingEntry "github.com/YuanshengClaw" "brsvh";

              "github.com/brsvh/*" =
                mappingEntry "github.com/brsvh" "brsvh";
            };
      };
    };
  };
}
