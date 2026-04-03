{
  home,
  pkgs,
  ...
}:
{
  imports = [
    home.profiles.locale
  ];

  i18n = {
    glibcLocales = pkgs.glibcLocales.override {
      allLocales = false;

      locales = [
        "en_US.UTF-8/UTF-8"
        "zh_CN.UTF-8/UTF-8"
      ];
    };
  };
}
