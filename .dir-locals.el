;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "ActivateKeys ActiveByDefault
AllowInputMethodForPassword AltTriggerKeys Apheleia AutoSavePeriod
Backtrace Citre ClearPasswordAfter CompactInputMethodInformation
CustomXkbOption DeactivateKeys DefaultIM DefaultPageSize Dired
DisabledAddons EasyPG Eglot Eldoc EnabledAddons EnumerateBackwardKeys
EnumerateForwardKeys EnumerateGroupBackwardKeys
EnumerateGroupForwardKeys EnumerateSkipFirst EnumerateWithTriggerKeys
Eshell FallbackSpellLanguage Fixit Flymake Hanja Hankaku
HiddenNotifications IgnorePasswordFromPasswordManager LaTeX
Macroexpand Magit Magit's Minibuffer ModifierOnlyKeyTimeout Modus
NextCandidate NextPage OverrideXkbOption PastePrimaryKey Plex
PreeditEnabledByDefault PreloadInputMethod PrevCandidate PrevPage
Rmail Romaja ShareInputState ShowFirstInputMethodInformation
ShowInputMethodInformation ShowPassword ShowPreeditForPassword
TogglePreedit Treemacs TriggerKey TriggerKeys Vertico Zenkaku Zswap
adwaita allowUnfree antialiasing apm authinfo autocd autoload
autoloads azaleoid backend baz bg bgrt bingshan bluetooth btrfs cachix
cdspell cgroups charset checkwinsize citre cmdhist cond config
consolefonts ctags ctrl dae dconf dev devShells devshell devshells
dialout dirToAttrs direnv dirname dirspell disko editorconfig edP efi
elisp eln elpa emacs emacsclient enablement epa erasedups esac
eurlatgr facter fg filesystem flymake fontconfig gdm geiser
gitattributes gitignore globstar gnome gnupg gpg gpt gtags gtk gtkrc
guix gz histappend histfile hstr hstrnotiocsti ignoreboth ignorespace
infix iw jackaudio json keymap kvm lanzaboote layoutmode lba lefthook
lf libvirtd linux logicalmonitor loglevel loopback lp lzo mcp md
minibuffer mkDefault mkdir modeline monitorspec mrepl mtimes
networkmanager nftables nixfmt nixos nixosConfigurations nixpkgs
noatime noclobber openai openssh partlabel pinentry pipefail pkgs
plymouth pnp posframe posix pre psfu py pyi pyw quux rebase repo
resetStateWhenFocusIn ripgrep sbcl shopt
showInputMethodInformationWhenFocusIn smbios src ssd stdout subpixel
subscope subscopes substring subvols swapfile symlinked symlinks sysfs
systemd swapDevices tabspaces tmpfiles toml treefmt treemacs treesit
tty txt udev uefi uids unicode unstaged untabify untracked usb utf vbe
vfat virtualisation wayland writeback xdg xml xwayland yaml yml zbud
zh zpool zram zramSwap zsmalloc zstd zswap")))

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
