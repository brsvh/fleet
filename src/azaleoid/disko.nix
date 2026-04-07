{
  disko = {
    devices = {
      disk = {
        nvme0n1 = {
          content = {
            partitions = {
              efi = {
                content = {
                  format = "vfat";
                  mountpoint = "/efi";
                  type = "filesystem";
                };

                name = "efi";
                priority = 1;
                size = "1G";
                type = "EF00";
              };

              system = {
                content = {
                  extraArgs = [ "-f" ];

                  subvolumes = {
                    "/gnu" = {
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                        "ssd"
                      ];

                      mountpoint = "/gnu";
                      name = "gnu";
                    };

                    "/home" = {
                      mountOptions = [
                        "compress=zstd:1"
                        "ssd"
                      ];

                      mountpoint = "/home";
                      name = "home";
                    };

                    "/nix" = {
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                        "ssd"
                      ];

                      mountpoint = "/nix";
                      name = "nix";
                    };

                    "/nixos" = {
                      mountOptions = [
                        "compress=zstd:1"
                        "ssd"
                      ];

                      mountpoint = "/";
                      name = "nixos";
                    };

                    "/swap" = {
                      mountpoint = "/swap";

                      swap = {
                        swapfile = {
                          size = "16G";
                        };
                      };
                    };
                  };

                  type = "btrfs";
                };

                name = "system";
                size = "100%";
              };
            };

            type = "gpt";
          };

          device = "/dev/nvme0n1";
          type = "disk";
        };
      };
    };
  };
}
