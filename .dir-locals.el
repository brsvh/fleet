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
Batang Bitstream Cascadia Citre ClearPasswordAfter ClearType
CompactInputMethodInformation Consolas CustomXkbOption DeactivateKeys
DefaultIM DefaultPageSize DejaVu Dired DisabledAddons Dotum
DirectWrite EasyPG Eglot Eldoc EnabledAddons EnumerateBackwardKeys
EnumerateForwardKeys EnumerateGroupBackwardKeys
EnumerateGroupForwardKeys EnumerateSkipFirst EnumerateWithTriggerKeys
Eshell FZMingTiB FZSongTi FallbackSpellLanguage Fixit Flymake FreeMono
FreeSans FreeSerif FreeType Gulim Hanja Hankaku HanyiSong Helvetica
HiddenNotifications IgnorePasswordFromPasswordManager JhengHei LaTeX
Likhan Luxi Macroexpand Magit Magit's Mincho MingLiU Minibuffer
ModifierOnlyKeyTimeout Modus NSimSun NextCandidate NextPage
OverrideXkbOption PMingLiU PastePrimaryKey Plex
PreeditEnabledByDefault PreloadInputMethod PrevCandidate PrevPage
Rmail Romaja Segoe ShanHeiSun ShareInputState
ShowFirstInputMethodInformation ShowInputMethodInformation
ShowPassword ShowPreeditForPassword SimSun SungtiL Tahoma Thorndale
TogglePreedit Treemacs TriggerKey TriggerKeys UnBatang UnDotum Verdana
VerticalTabs Vertico Webdings WenQuanYi YaHei Zenkaku Zswap adwaita
allowUnfree antialias antialiasing apm authinfo autocd autohint
autoload autoloads azaleoid backend baz bg bgrt bingshan bluetooth
bool btrfs cachix cdspell cgroups charset checkwinsize citre cjk
cmdhist cn cond config consolefonts const ctags ctrl dae dconf dev
devShells devshell devshells dialout dirToAttrs direnv dirname
dirspell disko dtd edP editorconfig efi elisp eln elpa emacs
emacsclient enablement epa erasedups erythron esac eurlatgr facter fg
filesystem flymake fontconfig fontset frontend fwupd gdm geiser
gitattributes gitignore globaladvance globstar gnome gnupg gpg gpt
gtags gtk gtkrc guix gz hintslight hintstyle histappend histfile hk
hstr hstrnotiocsti ignoreboth ignorespace infix iw jackaudio json
keymap ko kvm lanzaboote layoutmode lba lcddefault lcdfilter lefthook
lf libvirtd linux logicalmonitor loglevel loopback lp lzo mcp md
minibuffer mkDefault mkdir modeline monitorspec mrepl mtimes
networkmanager nftables nixfmt nixos nixosConfigurations nixpkgs
noatime noclobber openai openclaw openssh partlabel pinentry pipefail
pixelsize pkgs plymouth pnp posframe posix pre psfu py pyi pyw qual
quux rebase repo resetStateWhenFocusIn rgb ripgrep sbcl sbctl shopt
showInputMethodInformationWhenFocusIn smbios src ssd stdout steipete
subpixel subscope subscopes substring subvols swapDevices swapfile
symlinked symlinks sysfs systemd tabspaces tmpfiles toml treefmt
treemacs treesit truetype tty tw txt udev uefi uids unicode unstaged
untabify untracked usb utf utils vbe vfat virtualisation wayland
waypipe wemeet writeback xdg xml xwayland yaml yml zbud zh zpool zram
zramSwap zsmalloc zstd zswap")))

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
