;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "apm azaleoid bluetooth btrfs config dev
devShells devshell devshells dirToAttrs direnv disko editorconfig efi
emacs facter filesystem gitignore gpt infix json lba lefthook lf linux
mkdir nixfmt nixos nixosConfigurations nixpkgs noatime pipefail pnp
rebase smbios src ssd subvols sysfs toml treefmt uefi usb untracked
utf vbe vfat virtualisation yaml yml zstd")))

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
