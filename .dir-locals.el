;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "ActivateKeys ActiveByDefault
AllowInputMethodForPassword AltTriggerKeys AutoSavePeriod
ClearPasswordAfter CompactInputMethodInformation CustomXkbOption
DeactivateKeys DefaultIM DefaultPageSize DisabledAddons EnabledAddons
EnumerateBackwardKeys EnumerateForwardKeys EnumerateGroupBackwardKeys
EnumerateGroupForwardKeys EnumerateSkipFirst EnumerateWithTriggerKeys
FallbackSpellLanguage Hanja Hankaku HiddenNotifications
IgnorePasswordFromPasswordManager ModifierOnlyKeyTimeout NextCandidate
NextPage OverrideXkbOption PastePrimaryKey PreeditEnabledByDefault
PreloadInputMethod PrevCandidate PrevPage Romaja ShareInputState
ShowFirstInputMethodInformation ShowInputMethodInformation
ShowPassword ShowPreeditForPassword TogglePreedit TriggerKey
TriggerKeys Zenkaku adwaita allowUnfree apm autocd azaleoid bg bgrt
bingshan bluetooth btrfs cachix cdspell cgroups checkwinsize cmdhist
cond config consolefonts ctrl dae dconf dev devShells devshell
devshells dialout dirToAttrs direnv dirname dirspell disko
editorconfig efi emacs enablement erasedups esac eurlatgr facter fg
filesystem gdm gitattributes gitignore globstar gnome gnupg gpg gpt
gtk gtkrc guix gz histappend histfile hstr hstrnotiocsti ignoreboth
ignorespace infix jackaudio json kvm lba lefthook lf libvirtd linux
loglevel loopback lp mkDefault mkdir networkmanager nftables nixfmt
nixos nixosConfigurations nixpkgs noatime noclobber openssh pinentry
pipefail plymouth pnp posix psfu rebase resetStateWhenFocusIn shopt
showInputMethodInformationWhenFocusIn smbios src ssd stdout subvols
swapfile symlinked symlinks sysfs systemd toml treefmt tty txt udev
uefi uids untracked usb utf vbe vfat virtualisation wayland xdg
xwayland yaml yml zh zram zstd")))

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
