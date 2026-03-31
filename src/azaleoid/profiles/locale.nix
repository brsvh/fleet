{
  system,
  ...
}:
{
  imports = [
    system.profiles.locale
  ];

  i18n = {
    extraLocales = [
      "zh_CN.UTF-8/UTF-8"
    ];
  };
}
