;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "allowUnfree apm autocd azaleoid bg bgrt
bluetooth btrfs cdspell cgroups checkwinsize cmdhist cond config ctrl
dev devShells devshell devshells dirToAttrs direnv dirname dirspell
disko editorconfig efi emacs erasedups esac facter fg filesystem
gitignore globstar gpt guix histappend histfile hstr hstrnotiocsti
ignoreboth ignorespace infix json lba lefthook lf linux mkDefault
mkdir nftables nixfmt nixos nixosConfigurations nixpkgs noatime
noclobber openssh pipefail plymouth pnp posix rebase shopt smbios src
ssd stdout subvols symlinked symlinks sysfs toml treefmt tty uefi uids
untracked usb utf vbe vfat virtualisation yaml yml zstd")))

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
