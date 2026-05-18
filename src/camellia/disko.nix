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
                  type = "filesystem";
                  format = "ext4";
                  extraArgs = [
                    "-L"
                    "nixos"
                  ];
                  mountpoint = "/";
                };

                end = "98585MiB";
                fs-type = "ext4";
                name = "root";
                part-type = "primary";
                start = "1MiB";
              }
              {
                content = {
                  type = "swap";
                  extraArgs = [
                    "-L"
                    "swap"
                  ];
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
