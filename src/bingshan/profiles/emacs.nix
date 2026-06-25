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
    concatStringsSep
    filter
    head
    mapAttrsToList
    toJSON
    toSentenceCase
    ;

  contact = config.accounts.contact.emacs;

  maildirBase =
    config.accounts.email.maildirBasePath;

  mails = filter (mail: mail.account.enable) (
    mapAttrsToList (name: account: {
      inherit
        account
        name
        ;
    }) config.accounts.email.accounts
  );

  primaryMails = filter (
    mail: mail.account.primary
  ) mails;

  secondaryMails = filter (
    mail: !mail.account.primary
  ) mails;

  primary = (head primaryMails).account;

  primaryMaildir = primary.maildir.absPath;

  primaryName = (head primaryMails).name;

  mkMaildir =
    account: folder:
    "/${account.maildir.path}/${folder}";

  mkPrimaryMaildir = mkMaildir primary;

  mkMu4eContext =
    mail:
    let
      inherit (mail)
        account
        name
        ;

      accountMaildir = mkMaildir account;

      accountMaildirPrefix = "/${account.maildir.path}/";
    in
    ''
      (make-mu4e-context
       :name ${toJSON name}
       :match-func
       (lambda (msg)
         (when msg
           (let ((maildir (mu4e-message-field msg :maildir)))
             (and maildir
                  (string-prefix-p ${toJSON accountMaildirPrefix}
                                   maildir)))))
       :vars
       '((user-mail-address . ${toJSON account.address})
         (user-full-name . ${toJSON account.realName})
         (mail-source-directory . ${toJSON account.maildir.absPath})
         (message-directory . ${toJSON account.maildir.absPath})
         (message-signature . ${toJSON account.signature.text})
         (mml-secure-openpgp-signers . (${toJSON account.gpg.key}))
         (mu4e-sent-folder . ${toJSON (accountMaildir "Sent")})
         (mu4e-drafts-folder . ${toJSON (accountMaildir "Drafts")})
         (mu4e-trash-folder . ${toJSON (accountMaildir "Trash")})
         (smime-certificate-directory . ${toJSON "${account.maildir.absPath}/certs/"})))
    '';

  mu4eEmailContexts = concatStringsSep "\n" (
    map mkMu4eContext (primaryMails ++ secondaryMails)
  );

  libext =
    pkgs.stdenv.targetPlatform.extensions.sharedLibrary;

  toJSON' = value: toJSON (toJSON value);
in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.fonts
    bingshan.profiles.git
    bingshan.profiles.global
    home.profiles.emacs
  ];

  home = {
    packages = with pkgs; [
      black
      clang-tools
      claude-agent-acp
      codesearch
      codex-acp
      curl
      emacs-lsp-booster
      hunspell
      hunspellDicts.en_US-large
      nerd-fonts.symbols-only
      nixd
      nixfmt
      openspec
      pyright
      ripgrep
      spec-kit
      wl-clipboard
      xclip
    ];
  };

  programs = {
    emacs = {
      earlyInitFile = bingshan.etc.emacs.early-init;

      extraConfig = ''
        (use-package bs-carddav
          :demand t

          :preface
          (require 'json)

          :custom
          (bs-carddav-addressbooks
           (json-parse-string ${toJSON' contact.addressbooks}
                              :object-type 'alist
                              :array-type 'list
                              :null-object nil
                              :false-object nil))

          (bs-carddav-writable-addressbooks
           (json-parse-string ${toJSON' contact.writableAddressbooks}
                              :object-type 'alist
                              :array-type 'list
                              :null-object nil
                              :false-object nil))

          (bs-carddav-read-only-addressbooks
           (json-parse-string ${toJSON' contact.readOnlyAddressbooks}
                              :object-type 'alist
                              :array-type 'list
                              :null-object nil
                              :false-object nil)))

        (use-package emacs
          :demand t
          :no-require t

          :custom
          (user-full-name "${primary.realName}"))

        (use-package emacs
          :demand t
          :no-require t
          :when (display-graphic-p)

          :config
          (set-fontset-font t 'cjk-misc (font-spec :family "Microsoft YaHei"))
          (set-fontset-font t 'han (font-spec :family "Microsoft YaHei")))

        (use-package epa-hook
          :config
          (add-to-list 'epa-file-encrypt-to "${primary.gpg.key}"))

        (use-package mail-source
          :custom
          (mail-source-directory "${primaryMaildir}"))

        (use-package message
          :custom
          (message-directory "${primaryMaildir}")
          (message-sendmail-envelope-from 'header)
          (message-signature "${primary.signature.text}"))

        (use-package mu4e
          :custom
          (mu4e-compose-context-policy 'ask)
          (mu4e-context-policy 'pick-first)
          (mu4e-maildir "${maildirBase}")
          (mu4e-sent-folder "${mkPrimaryMaildir "Sent"}")
          (mu4e-drafts-folder "${mkPrimaryMaildir "Drafts"}")
          (mu4e-trash-folder "${mkPrimaryMaildir "Trash"}")

          :config
          (setq mu4e-contexts
                (list
                 ${mu4eEmailContexts})))

        (use-package mu4e-bookmarks
          :custom
          (mu4e-bookmarks
           '(( :name "${toSentenceCase primaryName} inbox"
               :query "maildir:${mkPrimaryMaildir "INBOX"}"
               :key ?i)
             ( :name "${toSentenceCase primaryName} drafts"
               :query "maildir:${mkPrimaryMaildir "Drafts"}"
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
             ( :name "${toSentenceCase primaryName} sent messages"
               :query "maildir:${mkPrimaryMaildir "Sent"}"
               :key ?s)
             ( :name "${toSentenceCase primaryName} junk messages"
               :query "maildir:${mkPrimaryMaildir "Junk"}"
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
          (smime-certificate-directory "${primaryMaildir}/certs/"))

        (use-package smtpmail
          :custom
          (smtpmail-queue-dir "${maildirBase}/queued-mail/"))

        (use-package startup
          :demand t
          :no-require t

          :custom
          (user-mail-address "${primary.address}"))
      '';

      extraPackages =
        epkgs: with epkgs; [
          agent-recall
          agent-review
          agent-shell
          agent-shell-sidebar
          agent-shell-tramp
          agent-shell-manager
          agent-shell-knockknock
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
          consult-codesearch
          consult-contacts
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
          ebdb
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
          ghostel
          ghostel-dwim
          git-cliff
          git-modes
          haskell-mode
          haskell-ts-mode
          hl-todo
          htmlize
          ibuffer-project
          jieba-rs
          jinx
          macrostep-geiser
          magit
          magit-section
          marginalia
          modus-themes
          mu4e
          mu4e-alert
          mu4e-knockknock
          mwim
          nerd-icons
          nerd-icons-corfu
          nerd-icons-dired
          nerd-icons-ibuffer
          nix-mode
          nix-ts-mode
          openspec
          orderless
          org-appear
          org-contrib
          org-gtd
          org-modern
          org-modern-indent
          org-ql
          org-super-agenda
          org-vcard
          paredit
          pass
          plz
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

    git = {
      ignores = [
        "/.agent-shell"
      ];
    };
  };
}
