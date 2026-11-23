{
  system,
  ...
}:
let
  archiveRoot = "/srv/archive";
  archivePublicRoot = "${archiveRoot}/public";
in
{
  imports = [
    system.profiles.nginx
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        80
      ];
    };
  };

  services = {
    nginx = {
      virtualHosts = {
        "archive.bingshan.org" = {
          enableACME = true;
          forceSSL = true;
          root = archivePublicRoot;

          locations = {
            "/" = {
              extraConfig = ''
                autoindex on;
                disable_symlinks on;
                limit_except GET { deny all; }
              '';
            };
          };
        };
      };
    };
  };

  systemd = {
    tmpfiles = {
      rules = [
        # OpenSSH requires the chroot itself to be owned by root.
        "d ${archiveRoot} 0755 root root -"
        "d ${archivePublicRoot} 0755 archive archive -"
      ];
    };
  };
}
