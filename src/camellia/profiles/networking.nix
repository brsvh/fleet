{
  system,
  ...
}:
{
  imports = [
    system.profiles.dhcpcd
  ];

  networking = {
    interfaces = {
      ens3 = {
        tempAddress = "disabled";
      };
    };

    tempAddresses = "disabled";
  };
}
