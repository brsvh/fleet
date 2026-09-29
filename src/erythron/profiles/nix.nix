{
  system,
  ...
}:
{
  imports = [
    system.profiles.nix
  ];

  nix = {
    settings = {
      substituters = [
        "http://magnolia.tail.bingshan.org:5000?priority=30"
      ];

      trusted-public-keys = [
        "magnolia.tail.bingshan.org-1:VDtUX3qdn2o0sknJSDf0abndR7RwqnyNU4V4GKKJZpQ="
      ];
    };
  };
}
