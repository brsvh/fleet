;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "
ActivateKeys ActiveByDefault AllowInputMethodForPassword
AltTriggerKeys Andale Apheleia Arial AutoSavePeriod Backtrace Baekmuk
Batang Bitstream Citre ClearPasswordAfter
CompactInputMethodInformation CustomXkbOption DeactivateKeys DefaultIM
DefaultPageSize DejaVu Dired DisabledAddons Dotum EasyPG Eglot Eldoc
EnabledAddons EnumerateBackwardKeys EnumerateForwardKeys
EnumerateGroupBackwardKeys EnumerateGroupForwardKeys
EnumerateSkipFirst EnumerateWithTriggerKeys Eshell FZMingTiB FZSongTi
FallbackSpellLanguage Fixit Flymake FreeMono FreeSans FreeSerif Gulim
Hanja Hankaku HanyiSong Helvetica HiddenNotifications
IgnorePasswordFromPasswordManager LaTeX Likhan Luxi Macroexpand Magit
Magit's Mincho MingLiU Minibuffer ModifierOnlyKeyTimeout Modus NSimSun
NextCandidate NextPage OverrideXkbOption PMingLiU PastePrimaryKey Plex
PreeditEnabledByDefault PreloadInputMethod PrevCandidate PrevPage
Rmail Romaja ShanHeiSun ShareInputState
ShowFirstInputMethodInformation ShowInputMethodInformation
ShowPassword ShowPreeditForPassword SimSun SungtiL Tahoma Thorndale
TogglePreedit Treemacs TriggerKey TriggerKeys UnBatang UnDotum Verdana
Vertico Webdings WenQuanYi Zenkaku Zswap adwaita allowUnfree antialias
antialiasing apm authinfo autocd autohint autoload autoloads azaleoid
backend baz bg bgrt bingshan bluetooth bool btrfs cachix cdspell
cgroups charset checkwinsize citre cmdhist cond config consolefonts
const ctags ctrl dae dconf dev devShells devshell devshells dialout
dirToAttrs direnv dirname dirspell disko dtd edP editorconfig efi
elisp eln elpa emacs emacsclient enablement epa erasedups esac
eurlatgr facter fg filesystem flymake fontconfig gdm geiser
gitattributes gitignore globaladvance globstar gnome gnupg gpg gpt
gtags gtk gtkrc guix gz hintslight hintstyle histappend histfile hstr
hstrnotiocsti ignoreboth ignorespace infix iw jackaudio json keymap ko
kvm lanzaboote layoutmode lba lefthook lf libvirtd linux
logicalmonitor loglevel loopback lp lzo mcp md minibuffer mkDefault
mkdir modeline monitorspec mrepl mtimes networkmanager nftables nixfmt
nixos nixosConfigurations nixpkgs noatime noclobber openai openssh
partlabel pinentry pipefail pixelsize pkgs plymouth pnp posframe posix
pre psfu py pyi pyw qual quux rebase repo resetStateWhenFocusIn
ripgrep sbcl shopt showInputMethodInformationWhenFocusIn smbios src
ssd stdout subpixel subscope subscopes substring subvols swapDevices
swapfile symlinked symlinks sysfs systemd tabspaces tmpfiles toml
treefmt treemacs treesit tty txt udev uefi uids unicode unstaged
untabify untracked usb utf vbe vfat virtualisation wayland writeback
xdg xml xwayland yaml yml zbud zh zpool zram zramSwap zsmalloc zstd
zswap")))

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
