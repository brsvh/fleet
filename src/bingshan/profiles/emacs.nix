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
    concatLists
    concatMapStringsSep
    concatStringsSep
    filter
    findFirst
    getExe
    head
    mapAttrsToList
    pipe
    replaceStrings
    sort
    stringLength
    substring
    toJSON
    toSentenceCase
    ;

  calendars = attrValues config.accounts.calendar.accounts;

  contacts = config.accounts.contact.emacs;

  mails = mapAttrsToList (name: account: {
    inherit
      account
      name
      ;
  }) config.accounts.email.accounts;

  el = rec {
    cjkBoldItalicFont = toJSON "LXGW ZhenKai GB";
    cjkFont = toJSON "LXGW Neo ZhiSong";
    cjkItalicFont = toJSON "LXGW WenKai";

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
      pipe addressbooks [
        (mapAttrsToList (
          id: addressbook:
          "(${toJSON id} . ${genAddressbook addressbook})"
        ))
        (concatStringsSep "\n")
      ];

    genBool = value: if value then "t" else "nil";

    genCalendarDirectories =
      calendars:
      pipe calendars [
        (map (calendar: toJSON calendar.local.path))
        (concatStringsSep " ")
      ];

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
      account: role:
      "/${account.maildir.path}/${account.folders.${role}}";

    genMaildirQuery =
      account: role:
      ''maildir:"${genMailFolder account role}"'';

    genContactQuery =
      addresses:
      "("
      + concatMapStringsSep " OR " (
        address:
        "(from:${address} OR to:${address} OR cc:${address} OR bcc:${address})"
      ) addresses
      + ")";

    genContextQuery =
      mail:
      let
        root = ''maildir:"/${mail.account.maildir.path}/"'';
      in
      if mail.account.primary then
        if mail.sharedMaildirAddresses == [ ] then
          root
        else
          "(${root}) AND NOT (${genContactQuery mail.sharedMaildirAddresses})"
      else if mail.sharesPrimaryMaildir then
        "(${root}) AND (${genContactQuery mail.addresses})"
      else
        root;

    genScopedQuery =
      mail: query:
      "(${genContextQuery mail}) AND (${query})";

    genMu4eBookmark = mail: name: query: key: ''
      ( :name ${toJSON name}
        :query ${toJSON (genScopedQuery mail query)}
        :key ?${key}
        :source ${toJSON mail.name})
    '';

    genMu4eBookmarks =
      mail:
      let
        accountName = toSentenceCase mail.name;
        account = mail.account;
      in
      concatStringsSep "\n" [
        (genMu4eBookmark mail "${accountName} inbox"
          (genMaildirQuery account "inbox")
          "i"
        )
        (genMu4eBookmark mail "${accountName} drafts"
          (genMaildirQuery account "drafts")
          "d"
        )
        (genMu4eBookmark mail "Unread messages"
          "flag:unread AND NOT flag:trashed"
          "u"
        )
        (genMu4eBookmark mail "Today's messages"
          "date:today..now"
          "t"
        )
        (genMu4eBookmark mail "Last 3 days" "date:3d..now"
          "3"
        )
        (genMu4eBookmark mail "Last 7 days" "date:7d..now"
          "7"
        )
        (genMu4eBookmark mail
          "${accountName} sent messages"
          (genMaildirQuery account "sent")
          "s"
        )
        (genMu4eBookmark mail
          "${accountName} junk messages"
          (genMaildirQuery account "junk")
          "j"
        )
        ''
          ( :name "Context summary"
            :query ${toJSON (genContextQuery mail)}
            :source ${toJSON mail.name}
            :bs-hidden t
            :bs-context-summary t)
        ''
        (genMu4eMaildirQueries mail)
      ];

    mu4eMaildirRoles = [
      {
        key = "d";
        role = "drafts";
      }
      {
        key = "i";
        role = "inbox";
      }
      {
        key = "j";
        role = "junk";
      }
      {
        key = "s";
        role = "sent";
      }
      {
        key = "t";
        role = "trash";
      }
    ];

    genMu4eMaildir =
      mail: folder:
      let
        path = genMailFolder mail.account folder.role;

        name = pipe path [
          (substring 1 (stringLength path - 1))
          (replaceStrings [ "/" ] [ " " ])
        ];
      in
      {
        inherit (folder) key;

        inherit name path;

        query = genScopedQuery mail (
          genMaildirQuery mail.account folder.role
        );
      };

    genMu4eMaildirs =
      mail:
      pipe mu4eMaildirRoles [
        (map (genMu4eMaildir mail))
        (sort (left: right: left.name < right.name))
      ];

    genMu4eMaildirQueries =
      mail:
      pipe (genMu4eMaildirs mail) [
        (map (folder: ''
          ( :name ${toJSON folder.name}
            :query ${toJSON folder.query}
            :source ${toJSON mail.name}
            :bs-hidden t
            :bs-maildir t
            :bs-maildir-key ?${folder.key}
            :maildir ${toJSON folder.path})
        ''))
        (concatStringsSep "\n")
      ];

    genMu4eMaildirShortcuts =
      mail:
      pipe (genMu4eMaildirs mail) [
        (map (folder: ''
          ( :maildir ${toJSON folder.path}
            :key ?${folder.key})
        ''))
        (concatStringsSep "\n")
      ];

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
          role: toJSON (genMailFolder account role);

        isPrimary = account.primary;

        maildir = toJSON "/${account.maildir.path}/";

        maildirAbsPath = toJSON account.maildir.absPath;

        realName = toJSON account.realName;

        addresses' = pipe mail.addresses [
          (map toJSON)
          (concatStringsSep " ")
        ];

        sharedMaildirAddresses' =
          pipe sharedMaildirAddresses
            [
              (map toJSON)
              (concatStringsSep " ")
            ];

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
                    (mapcar #'regexp-quote '(${addresses'})))
                 ''
             }))
         :vars
         '((user-mail-address . ${address})
           (user-full-name . ${realName})
           (mail-source-directory . ${maildirAbsPath})
           (message-directory . ${maildirAbsPath})
           (message-signature . ${signature})
           (mml-secure-openpgp-signers . (${signkey}))
           (mu4e-sent-folder . ${genMailFolder' "sent"})
           (mu4e-drafts-folder . ${genMailFolder' "drafts"})
           (mu4e-trash-folder . ${genMailFolder' "trash"})
           (mu4e-bookmarks . (${genMu4eBookmarks mail}))
           (mu4e-maildir-shortcuts . (${genMu4eMaildirShortcuts mail}))
           (smime-certificate-directory . ${certdirAbsPath})))
      '';

    genSyncCollections =
      collections:
      pipe collections [
        (map toJSON)
        (concatStringsSep " ")
      ];
  };

in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.fonts
    bingshan.profiles.git
    bingshan.profiles.global
    bingshan.profiles.grip
    bingshan.profiles.tex
    home.profiles.emacs
  ];

  home = {
    packages = with pkgs; [
      black
      clang-tools
      codesearch
      curl
      emacs-lsp-booster
      haskell-language-server
      hunspell
      hunspellDicts.en_US-large
      imagemagick
      lxgw-wenkai
      lxgwPackages.neo-zhisong
      lxgwPackages.zhenkai
      nerd-fonts.symbols-only
      nixd
      nixfmt
      poppler-utils
      pyright
      ripgrep
      typescript
      vscode-json-languageserver
      wl-clipboard
      xclip
    ];
  };

  programs = {
    emacs = {
      earlyInitFile = bingshan.etc.emacs.early-init;

      extraConfig =
        let
          contactAddressbooks = contacts.addressbooks;

          contactDefaultAddressbook =
            contacts.defaultAddressbook;

          contactSyncCollections = contacts.syncCollections;

          enabledCalendars = filter (
            calendar: calendar.khal.enable
          ) calendars;

          enabledMails = filter (
            mail: mail.account.enable
          ) mails;

          primaryMailEntry =
            findFirst (mail: mail.account.primary)
              (throw "Emacs requires an enabled primary email account")
              enabledMails;

          primaryMaildir =
            primaryMailEntry.account.maildir.absPath;

          maildirBase =
            config.accounts.email.maildirBasePath;

          mailAddresses =
            mail:
            [ mail.account.address ] ++ mail.account.aliases;

          sharesPrimaryMaildir =
            candidate:
            candidate.account.maildir.path
            == primaryMailEntry.account.maildir.path;

          sharedMails = filter (
            candidate:
            !candidate.account.primary
            && sharesPrimaryMaildir candidate
          ) enabledMails;

          sharedMaildirAddresses = pipe sharedMails [
            (map mailAddresses)
            concatLists
          ];

          prepareMail =
            candidate:
            candidate
            // {
              inherit sharedMaildirAddresses;

              addresses = mailAddresses candidate;
              sharesPrimaryMaildir = sharesPrimaryMaildir candidate;
            };

          primaryMail = prepareMail primaryMailEntry;

          mu4eContexts =
            let
              genMailContext =
                account: el.genMu4eContext (prepareMail account);
            in
            pipe
              (
                [ primaryMailEntry ]
                ++ sharedMails
                ++ filter (
                  candidate:
                  !candidate.account.primary
                  && !sharesPrimaryMaildir candidate
                ) enabledMails
              )
              [
                (map genMailContext)
                (concatStringsSep "\n")
              ];

        in
        with el;
        ''
          (eval-when-compile
            (require 'use-package))

          (eval-and-compile
            ;; default.el is compiled separately from the user init files.
            (setq use-package-always-defer t
                  use-package-expand-minimally t
                  use-package-compute-statistics nil
                  use-package-ensure-function #'ignore
                  use-package-hook-name-suffix nil))

          (use-package bs-contacts
            :custom
            (bs-contacts-addressbooks '(${genAddressbooks contactAddressbooks}))
            (bs-contacts-default-addressbook '${genDefaultAddressbook contactDefaultAddressbook})
            (bs-contacts-sync-collections '(${genSyncCollections contactSyncCollections}))

            :defer t)

          (use-package bs-htmlize
            :custom
            (bs-htmlize-browser "${getExe pkgs.google-chrome}")

            :defer t)

          (use-package bs-khal
            :custom
            (bs-khal-calendar-directories '(${genCalendarDirectories enabledCalendars}))
            (bs-khal-default-calendar ${genDefaultCalendarName enabledCalendars})

            :defer t)

          (use-package emacs
            :custom
            (user-full-name "${primaryMail.account.realName}")

            :demand t
            :no-require t)

          (use-package epa-hook
            :config
            (add-to-list 'epa-file-encrypt-to "${primaryMail.account.gpg.key}")

            :defer t)

          (use-package fontset
            :config
            (dolist (script '(han cjk-misc))
              (set-fontset-font t script
                                (font-spec :family ${cjkFont})))

            ;; Use distinct upright Chinese typefaces for emphasis while leaving
            ;; the Latin weight and slant to their faces.
            (dolist (entry '(("fontset-bsitalic" . ${cjkItalicFont})
                             ("fontset-bsbolditalic" . ${cjkBoldItalicFont})))
              (let ((fontset
                     (or (query-fontset (car entry))
                         (create-fontset-from-fontset-spec
                          (concat "-*-*-*-*-*-*-*-*-*-*-*-*-" (car entry))))))
                (dolist (script '(han cjk-misc))
                  (set-fontset-font fontset script
                                    (font-spec :family (cdr entry)
                                               :weight 'normal
                                               :slant 'normal)))))

            :hook
            ;; Restore the fontsets after theme changes and for new GUI frames.
            ((after-make-frame-functions
              bs-first-ui-hook
              modus-themes-after-load-theme-hook)
             .
             (lambda (&optional frame)
               (dolist (frame (if frame (list frame) (frame-list)))
                 (when (display-graphic-p frame)
                   (set-face-attribute 'italic frame
                                       :fontset "fontset-bsitalic")
                   (set-face-attribute 'bold-italic frame
                                       :fontset "fontset-bsbolditalic")))))

            :demand t)

          (use-package info
            :custom
            (Info-additional-directory-list '("${pkgs.mu.mu4e}/share/info"))

            :defer t)

          (use-package mail-source
            :custom
            (mail-source-directory "${primaryMaildir}")

            :defer t)

          (use-package message
            :custom
            (message-directory "${primaryMaildir}")
            (message-sendmail-envelope-from 'header)
            (message-signature "${primaryMail.account.signature.text}")

            :defer t)

          (use-package mu4e-bookmarks
            :custom
            (mu4e-bookmarks '(${genMu4eBookmarks primaryMail}))

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
            (mu4e-sent-folder "${genMailFolder primaryMail.account "sent"}")
            (mu4e-drafts-folder "${genMailFolder primaryMail.account "drafts"}")
            (mu4e-trash-folder "${genMailFolder primaryMail.account "trash"}")
            (mu4e-maildir-shortcuts '(${genMu4eMaildirShortcuts primaryMail}))

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
            (smime-certificate-directory "${primaryMaildir}/certs/")

            :defer t)

          (use-package smtpmail
            :custom
            (smtpmail-queue-dir "${maildirBase}/queued-mail/")

            :defer t)

          (use-package startup
            :demand t
            :no-require t

            :custom
            (user-mail-address "${primaryMail.account.address}"))
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
          anzu
          apheleia
          auctex
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
          debbugs
          denote
          denote-explore
          denote-journal
          denote-menu
          denote-org
          denote-search
          denote-sequence
          diff-hl
          diredfl
          doom-modeline
          editorconfig
          eglot
          eglot-booster
          eldoc-box
          eldoc-mouse
          elfeed
          elfeed-org
          elfeed-score
          elfeed-webkit
          elfeed-x
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
          pdf-tools
          plz
          proofread
          proofread-popup
          rainbow-delimiters
          recursion-indicator
          sly
          sly-asdf
          sly-macrostep
          sly-named-readtables
          sly-stepper
          smartparens
          spacious-padding
          switch-window
          tabspaces
          tessera
          tessera-x
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
  };

  xdg = {
    configFile = {
      "emacs/gnus-init.el" = {
        source = bingshan.etc.emacs.gnus-init;
      };
    };
  };
}
