{
  system,
  ...
}:
{
  imports = [
    system.profiles.inn
  ];

  services = {
    inn = {
      role = "replica";
    };
  };
}
