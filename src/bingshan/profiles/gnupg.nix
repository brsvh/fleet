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
        "F0270F0B2CDA621249E7A6B5A37817FE5B501BF1"
      ];
    };
  };
}
