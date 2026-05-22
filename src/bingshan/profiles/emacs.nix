{
  bingshan,
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    head
    ;

  email = head (
    filter (
      account: account.enable && account.primary
    ) (attrValues config.accounts.email.accounts)
  );

  libext =
    pkgs.stdenv.targetPlatform.extensions.sharedLibrary;

  maildir = email.maildir.absPath;

  maildirBase =
    config.accounts.email.maildirBasePath;

  mkMaildir =
    folder: "/${email.maildir.path}/${folder}";
in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.fonts
    bingshan.profiles.global
    home.profiles.emacs
  ];

  home = {
    packages = with pkgs; [
      black
      clang-tools
      codesearch
      emacs-lsp-booster
      hunspell
      hunspellDicts.en_US-large
      nerd-fonts.symbols-only
      nixd
      nixfmt
      pyright
      ripgrep
      silver-searcher
    ];
  };

  programs = {
    emacs = {
      earlyInitFile = bingshan.etc.emacs.early-init;

      extraConfig = ''
        (use-package emacs
          :demand t
          :no-require t

          :custom
          (user-full-name "${email.realName}"))

        (use-package emacs
          :demand t
          :no-require t
          :when (display-graphic-p)

          :config
          (set-fontset-font t 'cjk-misc (font-spec :family "Microsoft YaHei"))
          (set-fontset-font t 'han (font-spec :family "Microsoft YaHei")))

        (use-package epa-hook
          :config
          (add-to-list 'epa-file-encrypt-to "${email.gpg.key}"))

        (use-package mail-source
          :custom
          (mail-source-directory "${maildir}"))

        (use-package message
          :custom
          (message-directory "${maildir}")
          (message-sendmail-envelope-from 'header)
          (message-signature "${email.signature.text}"))

        (use-package mu4e
          :custom
          (mu4e-maildir "${maildirBase}")
          (mu4e-sent-folder "${mkMaildir "Sent"}")
          (mu4e-drafts-folder "${mkMaildir "Drafts"}")
          (mu4e-trash-folder "${mkMaildir "Trash"}"))

        (use-package mu4e-bookmarks
          :custom
          (mu4e-bookmarks
           '(( :name "${email.realName}'s inbox"
               :query "maildir:${mkMaildir "INBOX"}"
               :key ?i)
             ( :name "${email.realName}'s drafts"
               :query "maildir:${mkMaildir "Drafts"}"
               :key ?d)
             ( :name "Unread messages"
               :query "flag:unread AND NOT flag:trashed"
               :key ?u)
             ( :name "Today's messages"
               :query "date:today..now"
               :key ?t)
             ( :name "Last 3 days"
               :query "date:3d..now"
               :key ?3)
             ( :name "Last 7 days"
               :query "date:7d..now"
               :key ?7)
             ( :name "${email.realName}'s sent messages"
               :query "maildir:${mkMaildir "Sent"}"
               :key ?s)
             ( :name "${email.realName}'s junk messages"
               :query "maildir:${mkMaildir "Junk"}"
               :key ?j))))

        (use-package mu4e-update
          :custom
          (mu4e-get-mail-command "offlineimap -u basic -o || true"))

        (use-package sendmail
          :custom
          (mail-envelope-from 'header)
          (mail-specify-envelope-from t)
          (send-mail-function 'sendmail-send-it)
          (sendmail-program "msmtp"))

        (use-package smime
          :custom
          (smime-certificate-directory "${maildir}/certs/"))

        (use-package startup
          :demand t
          :no-require t

          :custom
          (user-mail-address "${email.address}"))
      '';

      extraPackages =
        epkgs: with epkgs; [
          anzu
          apheleia
          beframe
          benchmark-init
          blamer
          bs
          bufferlo
          calfw
          cape
          citar
          citar-denote
          citar-embark
          citre
          codex-ide
          consult
          consult-ag
          consult-codesearch
          consult-denote
          consult-eglot
          consult-eglot-embark
          consult-jinx
          consult-mu
          consult-project-extra
          corfu
          corfu-candidate-overlay
          denote
          denote-explore
          denote-journal
          denote-menu
          denote-org
          denote-search
          diff-hl
          diredfl
          doom-modeline
          eat
          eat-dwim
          edit-indirect
          editorconfig
          eglot
          eglot-booster
          eldoc-box
          eldoc-mouse
          emacs-gc-stats
          embark
          embark-consult
          envrc
          flymake-popon
          form-feed
          geiser
          geiser-guile
          git-cliff
          git-modes
          haskell-mode
          haskell-ts-mode
          hl-todo
          htmlize
          ibuffer-project
          jinx
          macrostep-geiser
          magit
          magit-section
          marginalia
          modus-themes
          mu4e
          mu4e-alert
          mwim
          nerd-icons
          nerd-icons-corfu
          nerd-icons-dired
          nerd-icons-ibuffer
          nix-mode
          nix-ts-mode
          orderless
          org-appear
          org-contrib
          org-gtd
          org-modern
          org-modern-indent
          org-ql
          org-super-agenda
          paredit
          pass
          rainbow-delimiters
          sly
          sly-asdf
          sly-macrostep
          sly-named-readtables
          sly-stepper
          smartparens
          spacious-padding
          switch-window
          tabspaces
          treemacs
          treemacs-magit
          treemacs-nerd-icons
          treemacs-tab-bar
          unicode-fonts
          vertico
          vui
          winum
          with-editor
        ];

      initFile = bingshan.etc.emacs.init;

      package = pkgs.emacs-git-pgtk;
    };
  };
}
