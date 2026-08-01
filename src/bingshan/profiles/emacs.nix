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
    concatStringsSep
    filter
    findFirst
    head
    mapAttrsToList
    toJSON
    toSentenceCase
    ;

  calendars = filter (
    calendar: calendar.khal.enable
  ) (attrValues config.accounts.calendar.accounts);

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

  mail =
    findFirst (mail: mail.account.primary)
      (throw "Emacs requires an enabled primary email account")
      mails;

  maildir = mail.account.maildir.absPath;

  el = rec {
    cjkFont = toJSON "Zhuque Fangsong (technical preview)";

    genAddressbook =
      addressbook:
      let
        accountName = toJSON addressbook.accountName;
        addressbookId = toJSON addressbook.addressbookId;
        default = genBool addressbook.default;
        id = toJSON addressbook.id;
        khardName = toJSON addressbook.khardName;
        name = toJSON addressbook.name;
        path = toJSON addressbook.path;
        readOnly = genBool addressbook.readOnly;
        syncCollection = toJSON addressbook.syncCollection;
      in
      ''
        ((accountName . ${accountName})
         (addressbookId . ${addressbookId})
         (default . ${default})
         (id . ${id})
         (khardName . ${khardName})
         (name . ${name})
         (path . ${path})
         (readOnly . ${readOnly})
         (syncCollection . ${syncCollection}))
      '';

    genAddressbooks =
      addressbooks:
      concatStringsSep "\n" (
        mapAttrsToList (
          id: addressbook:
          "(${toJSON id} . ${genAddressbook addressbook})"
        ) addressbooks
      );

    genBool = value: if value then "t" else "nil";

    genCalendarDirectories =
      calendars:
      concatStringsSep " " (
        map (
          calendar: toJSON calendar.local.path
        ) calendars
      );

    genDefaultAddressbook =
      addressbook:
      if addressbook == null then
        "nil"
      else
        genAddressbook addressbook;

    genDefaultCalendarName =
      calendars:
      let
        calendar =
          findFirst (calendar: calendar.primary)
            (throw "Emacs requires a khal-enabled primary calendar account")
            calendars;
      in
      toJSON (
        if calendar.primaryCollection == null then
          calendar.name
        else
          calendar.primaryCollection
      );

    genMailFolder =
      account: folder:
      "/${account.maildir.path}/${folder}";

    genMu4eContext =
      mail:
      let
        inherit (mail)
          account
          sharedMaildirAddresses
          sharesPrimaryMaildir
          ;

        name = toJSON mail.name;

        address = toJSON account.address;

        certdirAbsPath = toJSON "${account.maildir.absPath}/certs/";

        genMailFolder' =
          folder: toJSON (genMailFolder account folder);

        isPrimary = account.primary;

        maildir = toJSON "/${account.maildir.path}/";

        maildirAbsPath = toJSON account.maildir.absPath;

        realName = toJSON account.realName;

        sharedMaildirAddresses' = concatStringsSep " " (
          map toJSON sharedMaildirAddresses
        );

        signature = toJSON account.signature.text;

        signkey = toJSON account.gpg.key;
      in
      ''
        (make-mu4e-context
         :name ${name}
         :match-func
         (lambda (msg)
           (when msg
             ${
               if isPrimary then
                 ''
                   (let ((maildir (mu4e-message-field msg :maildir)))
                     (and maildir
                          (string-prefix-p ${maildir} maildir)
                          (not
                           (mu4e-message-contact-field-matches
                   	 msg
                   	 '( :from :to :cc :bcc)
                   	 (mapcar #'regexp-quote '(${sharedMaildirAddresses'}))))))
                 ''
               else if !sharesPrimaryMaildir then
                 ''
                   (let ((maildir (mu4e-message-field msg :maildir)))
                     (and maildir
                          (string-prefix-p ${maildir} maildir)))
                 ''
               else
                 ''
                   (mu4e-message-contact-field-matches
                    msg
                    '( :from :to :cc :bcc)
                    (regexp-quote ${address}))
                 ''
             }))
         :vars
         '((user-mail-address . ${address})
           (user-full-name . ${realName})
           (mail-source-directory . ${maildirAbsPath})
           (message-directory . ${maildirAbsPath})
           (message-signature . ${signature})
           (mml-secure-openpgp-signers . (${signkey}))
           (mu4e-sent-folder . ${genMailFolder' "Sent"})
           (mu4e-drafts-folder . ${genMailFolder' "Drafts"})
           (mu4e-trash-folder . ${genMailFolder' "Trash"})
           (smime-certificate-directory . ${certdirAbsPath})))
      '';

    genSyncCollections =
      collections:
      concatStringsSep " " (map toJSON collections);
  };

  mu4eContexts =
    let
      sameMaildir =
        candidate:
        candidate.account.maildir.path
        == mail.account.maildir.path;

      shared = filter (
        mail: !mail.account.primary && sameMaildir mail
      ) mails;

      addresses = map (
        mail: mail.account.address
      ) shared;

      gen =
        mail:
        el.genMu4eContext (
          mail
          // {
            sharedMaildirAddresses = addresses;

            sharesPrimaryMaildir = sameMaildir mail;
          }
        );
    in
    concatStringsSep "\n" (
      map gen (
        [ mail ]
        ++ shared
        ++ filter (
          mail: !mail.account.primary && !sameMaildir mail
        ) mails
      )
    );
in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.fonts
    bingshan.profiles.git
    bingshan.profiles.global
    bingshan.profiles.grip
    home.profiles.emacs
  ];

  home = {
    packages =
      (with pkgs; [
        black
        clang-tools
        codesearch
        curl
        emacs-lsp-booster
        haskell-language-server
        hunspell
        hunspellDicts.en_US-large
        nerd-fonts.symbols-only
        nixd
        nixfmt
        pyright
        ripgrep
        trionestypePackages.zhuque-fangsong
        typescript-go
        vscode-json-languageserver
        wl-clipboard
        xclip
      ])
      ++ (with pkgs.llm-agents; [
        claude-agent-acp
        codex
        codex-acp
        openspec
        spec-kit
      ]);
  };

  programs = {
    emacs = {
      earlyInitFile = bingshan.etc.emacs.early-init;

      extraConfig =
        let
          inherit (contact)
            addressbooks
            defaultAddressbook
            syncCollections
            ;
        in
        with el;
        ''
          (use-package bs-contacts
            :custom
            (bs-contacts-addressbooks '(${genAddressbooks addressbooks}))

            (bs-contacts-default-addressbook '${genDefaultAddressbook defaultAddressbook})

            (bs-contacts-sync-collections '(${genSyncCollections syncCollections}))

            :defer t)

          (use-package bs-khal
            :custom
            (bs-khal-calendar-directories '(${genCalendarDirectories calendars}))

            (bs-khal-default-calendar ${genDefaultCalendarName calendars})

            :defer t)

          (use-package emacs
            :demand t
            :no-require t

            :custom
            (user-full-name "${mail.account.realName}"))

          (use-package emacs
            :demand t
            :no-require t
            :when (display-graphic-p)

            :config
            (set-fontset-font t 'cjk-misc (font-spec :family ${cjkFont}))
            (set-fontset-font t 'han (font-spec :family ${cjkFont})))

          (use-package epa-hook
            :config
            (add-to-list 'epa-file-encrypt-to "${mail.account.gpg.key}")

            :defer t)

          (use-package info
            :custom
            (Info-additional-directory-list '("${pkgs.mu.mu4e}/share/info"))

            :defer t)

          (use-package mail-source
            :custom
            (mail-source-directory "${maildir}")

            :defer t)

          (use-package message
            :custom
            (message-directory "${maildir}")
            (message-sendmail-envelope-from 'header)
            (message-signature "${mail.account.signature.text}")

            :defer t)

          (use-package mu4e-bookmarks
            :custom
            (mu4e-bookmarks
             '(( :name "${toSentenceCase mail.name} inbox"
                 :query "maildir:${genMailFolder mail.account "INBOX"}"
                 :key ?i)
               ( :name "${toSentenceCase mail.name} drafts"
                 :query "maildir:${genMailFolder mail.account "Drafts"}"
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
               ( :name "${toSentenceCase mail.name} sent messages"
                 :query "maildir:${genMailFolder mail.account "Sent"}"
                 :key ?s)
               ( :name "${toSentenceCase mail.name} junk messages"
                 :query "maildir:${genMailFolder mail.account "Junk"}"
                 :key ?j)))

            :defer t)

          (use-package mu4e-context
            :custom
            (mu4e-context-policy 'pick-first)

            :config
            (setq mu4e-contexts (list ${mu4eContexts}))

            :defer t)

          (use-package mu4e-draft
            :custom
            (mu4e-compose-context-policy 'ask)

            :defer t)

          (use-package mu4e-folders
            :custom
            (mu4e-sent-folder "${genMailFolder mail.account "Sent"}")
            (mu4e-drafts-folder "${genMailFolder mail.account "Drafts"}")
            (mu4e-trash-folder "${genMailFolder mail.account "Trash"}")

            :defer t)

          (use-package mu4e-message
            :commands (mu4e-message-contact-field-matches
                       mu4e-message-field)

            :defer t)

          (use-package mu4e-update
            :custom
            (mu4e-get-mail-command "true")

            :defer t)

          (use-package sendmail
            :custom
            (mail-envelope-from 'header)
            (mail-specify-envelope-from t)
            (send-mail-function 'sendmail-send-it)
            (sendmail-program "msmtp")

            :defer t)

          (use-package smime
            :custom
            (smime-certificate-directory "${maildir}/certs/")

            :defer t)

          (use-package smtpmail
            :custom
            (smtpmail-queue-dir "${maildirBase}/queued-mail/")

            :defer t)

          (use-package startup
            :demand t
            :no-require t

            :custom
            (user-mail-address "${mail.account.address}"))
        '';

      extraEarlyConfig =
        with el;
        let
          font = head config.fonts.fontconfig.defaultFonts.monospace;

          monospace = toJSON font;
        in
        ''
          (set-face-attribute 'default nil :family ${monospace})
          (set-face-attribute 'fixed-pitch nil :family ${monospace})
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
          calfw-org
          cape
          citar
          citar-denote
          citar-embark
          citre
          codex-ide
          consult
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
          gptel
          grip-mode
          haskell-mode
          haskell-ts-mode
          hl-todo
          htmlize
          ibuffer-project
          jieba-rs
          jinx
          khalel
          llm
          macrostep-geiser
          magit
          magit-section
          marginalia
          markdown-mode
          mcp-server
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
          paredit
          pass
          plz
          proofread
          proofread-popup
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

      package = pkgs.emacs-git-pgtk.override {
        withXwidgets = true;
      };
    };

    git = {
      ignores = [
        "/.agent-shell"
      ];
    };
  };
}
