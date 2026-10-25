{
  disko = {
    devices = {
      disk = {
        camellia = {
          content = {
            format = "msdos";

            partitions = [
              {
                bootable = true;

                content = {
                  extraArgs = [
                    "-L"
                    "nixos"
                  ];

                  format = "ext4";
                  mountpoint = "/";
                  type = "filesystem";
                };

                end = "98585MiB";
                fs-type = "ext4";
                name = "root";
                part-type = "primary";
                start = "1MiB";
              }
              {
                content = {
                  extraArgs = [
                    "-L"
                    "swap"
                  ];

                  type = "swap";
                };

                end = "100%";
                fs-type = "linux-swap";
                name = "swap";
                part-type = "primary";
                start = "98585MiB";
              }
            ];

            type = "table";
          };

          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-0";
          type = "disk";
        };
      };
    };
  };
}
