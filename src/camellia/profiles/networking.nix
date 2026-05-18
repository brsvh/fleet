{
  system,
  ...
}:
{
  imports = [
    system.profiles.dhcpcd
  ];

  networking = {
    domain = "bingshan.org";
    fqdn = "bingshan.org";

    interfaces = {
      ens3 = {
        tempAddress = "disabled";
      };
    };

    tempAddresses = "disabled";
  };
}
