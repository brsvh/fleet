{
  system,
  ...
}:
{
  imports = [
    system.profiles.grub
  ];

  boot = {
    loader = {
      grub = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-0";
      };
    };
  };
}
