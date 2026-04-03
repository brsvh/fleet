;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "adwaita allowUnfree apm autocd azaleoid bg
bgrt bingshan bluetooth btrfs cdspell cgroups checkwinsize cmdhist
cond config ctrl dconf dev devShells devshell devshells dialout
dirToAttrs direnv dirname dirspell disko editorconfig efi emacs
enablement erasedups esac facter fg filesystem gdm gitignore globstar
gnome gpt gtk gtkrc guix histappend histfile hstr hstrnotiocsti
ignoreboth ignorespace infix json jackaudio kvm lba lefthook lf
libvirtd linux loglevel lp mkDefault mkdir networkmanager nftables
nixfmt nixos nixosConfigurations nixpkgs noatime noclobber openssh
pinentry pipefail plymouth pnp posix rebase shopt smbios src ssd
stdout subvols symlinked symlinks sysfs systemd toml treefmt tty udev
uefi uids untracked usb utf vbe vfat virtualisation wayland xdg
xwayland yaml yml zh zstd")))

 (nix-mode
  .
  ;; Enforce a narrow, consistent formatting style for Nix code in
  ;; this project, keeping expressions compact and visually uniform.
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50")))))

 (nix-ts-mode
  .
  ;; Apply the same formatting constraints to Tree-sitter-based Nix
  ;; buffers, ensuring consistency regardless of the active major
  ;; mode.
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50"))))))
