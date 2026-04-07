{
  home,
  ...
}:
{
  imports = [
    home.profiles.gnupg
  ];

  services = {
    gpg-agent = {
      sshKeys = [
        "54A37140E8C5AD1C6B17C257AE6358E4C0B4ECE6"
      ];
    };
  };
}
