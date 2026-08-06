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
    filterAttrs
    findFirst
    head
    length
    mapAttrs
    mapAttrsToList
    optionalAttrs
    replaceStrings
    sort
    toJSON
    toSentenceCase
    zipAttrsWith
    ;

  calendars = attrValues config.accounts.calendar.accounts;

  contacts = config.accounts.contact.emacs;

  mails = mapAttrsToList (name: account: {
    inherit
      account
      name
      ;
  }) config.accounts.email.accounts;

  news = {
    eternal-september = {
      endpoint = "news.eternal-september.org:563_TLS";
      passwordCredential = "eternal-september";
      username = "bingshan";

      groups = {
        Architecture = [
          "comp.arch.fpga"
        ];

        Conversation = [
          "alt.folklore.computers"
          "alt.peeves"
        ];

        Emacs = [
          "comp.emacs"
        ];

        Food = [
          "rec.food.drink.tea"
        ];

        Games = [
          "rec.games.video.classic"
        ];

        Languages = [
          "alt.comp.lang.rust"
          "comp.lang.c"
          "comp.lang.c++"
          "comp.lang.haskell"
          "comp.lang.lisp"
          "comp.lang.scheme"
        ];

        Linux = [
          "comp.os.linux.networking"
        ];

        Music = [
          "rec.music.makers.synth"
        ];

        Reading = [
          "rec.arts.books"
        ];

        Security = [
          "comp.security.ssh"
        ];
      };
    };

    gmane = {
      endpoint = "news.gmane.io:119_STARTTLS";

      groups = {
        Emacs = [
          "gmane.emacs.devel"
          "gmane.emacs.help"
        ];

        Languages = [
          "gmane.lisp.asdf.devel"
          "gmane.lisp.guile.devel"
          "gmane.lisp.guile.user"
          "gmane.lisp.scheme.chez"
          "gmane.lisp.scheme.mit-scheme.devel"
        ];

        Linux = [
          "gmane.comp.kde.devel.general"
        ];

        "RISC-V" = [
          "gmane.comp.hardware.riscv.isa.devel"
          "gmane.comp.hardware.riscv.opensbi.devel"
          "gmane.linux.ports.riscv"
        ];

        Toolchain = [
          "gmane.comp.gcc.devel"
          "gmane.comp.gdb.devel"
          "gmane.comp.gnu.binutils"
          "gmane.comp.lib.glibc.alpha"
        ];
      };

      initialCatchupGroups = [
        "gmane.comp.kde.devel.general"
      ];

      mailingLists = {
        "gmane.comp.gcc.devel" = "gcc@gcc.gnu.org";
        "gmane.comp.gdb.devel" = "gdb@sourceware.org";
        "gmane.comp.gnu.binutils" =
          "binutils@sourceware.org";
        "gmane.comp.hardware.riscv.isa.devel" =
          "isa-dev@groups.riscv.org";
        "gmane.comp.hardware.riscv.opensbi.devel" =
          "opensbi@lists.infradead.org";
        "gmane.comp.kde.devel.general" =
          "kde-devel@kde.org";
        "gmane.comp.lib.glibc.alpha" =
          "libc-alpha@sourceware.org";
        "gmane.emacs.devel" = "emacs-devel@gnu.org";
        "gmane.emacs.help" = "help-gnu-emacs@gnu.org";
        "gmane.linux.ports.riscv" =
          "linux-riscv@lists.infradead.org";
        "gmane.lisp.asdf.devel" =
          "asdf-devel@lists.common-lisp.net";
        "gmane.lisp.guile.devel" = "guile-devel@gnu.org";
        "gmane.lisp.guile.user" = "guile-user@gnu.org";
        "gmane.lisp.scheme.chez" =
          "chez-scheme@googlegroups.com";
        "gmane.lisp.scheme.mit-scheme.devel" =
          "mit-scheme-devel@gnu.org";
      };
    };

    local = {
      groups = {
        Local = [
          "nndraft:delayed"
          "nndraft:drafts"
          "nndraft:queue"
        ];
      };
    };

    olduse = {
      endpoint = "olduse.net:11940";

      groups = {
        Architecture = [
          "net.arch"
        ];

        Conversation = [
          "net.general"
        ];

        Emacs = [
          "net.emacs"
        ];

        Film = [
          "net.movies"
        ];

        Games = [
          "net.games.trivia"
          "net.games.video"
        ];

        Languages = [
          "net.lang.c"
          "net.lang.c++"
          "net.lang.forth"
          "net.lang.lisp"
        ];

        Music = [
          "net.music.classical"
          "net.music.synth"
        ];

        Reading = [
          "net.books"
          "net.sf-lovers"
        ];

        Science = [
          "net.astro"
          "net.space"
        ];

        Security = [
          "net.crypt"
        ];

        Toolchain = [
          "mod.compilers"
          "mod.std.c"
        ];

        Unix = [
          "net.unix"
          "net.unix-wizards"
          "net.usenix"
        ];
      };
    };

    solani = {
      endpoint = "news.solani.org:563_TLS";
      passwordCredential = "solani";
      username = "bingshan";

      groups = {
        Architecture = [
          "comp.arch"
        ];

        Conversation = [
          "alt.callahans"
        ];

        Emacs = [
          "gnu.emacs.gnus"
        ];

        Film = [
          "rec.arts.movies.current-films"
          "rec.arts.movies.past-films"
        ];

        Games = [
          "rec.games.trivia"
        ];

        Languages = [
          "comp.lang.forth"
          "comp.programming"
        ];

        Linux = [
          "comp.os.linux.misc"
        ];

        Music = [
          "rec.music.classical.recordings"
          "rec.music.misc"
          "rec.music.rock-pop-r+b.1950s"
        ];

        Reading = [
          "rec.arts.sf.written"
        ];

        Science = [
          "sci.astro"
        ];

        Security = [
          "comp.security.unix"
        ];

        Unix = [
          "comp.unix.programmer"
        ];
      };
    };
  };

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

    genGnusMailingLists =
      mailingLists:
      concatStringsSep "\n" (
        map (
          entry:
          "(${toJSON entry.group} . ${toJSON entry.address})"
        ) mailingLists
      );

    genGnusMethod = ''
      (nntp "local"
            (nntp-address ${toJSON config.services.inn.bindAddress})
            (nntp-port-number ${toString config.services.inn.port})
            (nntp-open-connection-function nntp-open-network-stream))
    '';

    genGnusPreset = topics: initialCatchupGroups: ''
      (defun gnus--preset-setup ()
        "Apply the generated Gnus topic and subscription preset once."
        (require 'gnus-group)
        (require 'gnus-start)
        (require 'gnus-sum)
        (require 'gnus-topic)
        (require 'gnus-util)
        (require 'subr-x)
        (let* ((topics
                '(${genGnusTopics topics}))
               (initial-catchup-groups
                '(${genGnusStrings initialCatchupGroups}))
               (assigned-groups
                (delete-dups
                 (apply #'append
                        (mapcar
                         (lambda (topic)
                           (copy-sequence (cdr topic)))
                         gnus-topic-alist)))))
          (dolist (group
                   (apply #'append
                          (mapcar #'cdr topics)))
            (unless (or (string-prefix-p "nndraft:" group)
                        (gnus-get-info group))
              (condition-case err
                  (if (gnus-activate-group group)
                      (progn
                        (gnus-group-set-subscription
                         group
                         gnus-level-default-subscribed
                         t)
                        (when (member
                               group
                               initial-catchup-groups)
                          (gnus-group-catchup group 'all)))
                    (display-warning
                     'gnus-config
                     (format
                      "Could not activate Gnus group %s"
                      group)))
                (error
                 (display-warning
                  'gnus-config
                  (format
                   "Could not subscribe to Gnus group %s: %s"
                   group
                   (error-message-string err)))))))
          (unless gnus-topic-topology
            (setq gnus-topic-topology
                  '(("Gnus" visible nil nil))))
          (unless (assoc "Gnus" gnus-topic-alist)
            (push '("Gnus") gnus-topic-alist))
          (dolist (topic topics)
            (let* ((name (car topic))
                   (entry
                    (or (assoc name gnus-topic-alist)
                        (let ((entry (list name)))
                          (setq gnus-topic-alist
                                (append gnus-topic-alist
                                        (list entry)))
                          entry))))
              (dolist (group (cdr topic))
                (unless (member group assigned-groups)
                  (setcdr entry
                          (append (cdr entry) (list group)))
                  (push group assigned-groups)))
              (setcdr
               entry
               (sort
                (delete-dups (cdr entry))
                (lambda (left right)
                  (string-lessp
                   (string-remove-prefix
                    "gmane."
                    (gnus-group-real-name left))
                   (string-remove-prefix
                    "gmane."
                    (gnus-group-real-name right))))))
              (unless (gnus-topic-find-topology name)
                (setcdr
                 gnus-topic-topology
                 (append
                  (cdr gnus-topic-topology)
                  (list
                   (list
                    (list name 'visible nil nil))))))))
          (gnus-topic-sort-topics-1 gnus-topic-topology nil))
        (remove-hook 'gnus-setup-news-hook #'gnus--preset-setup))
    '';

    genGnusSourceNames = ''
      (${toJSON config.services.inn.bindAddress} . "Local")
    '';

    genGnusStrings =
      strings:
      concatStringsSep "\n" (map toJSON strings);

    genGnusTopics =
      topics:
      concatStringsSep "\n" (
        map (topic: ''
          (${toJSON topic.name}
           ${concatStringsSep "\n" (map toJSON topic.groups)})
        '') topics
      );

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
        name = replaceStrings [ "/" ] [ " " ] (
          builtins.substring 1 (
            builtins.stringLength path - 1
          ) path
        );
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
      sort (left: right: left.name < right.name) (
        map (genMu4eMaildir mail) mu4eMaildirRoles
      );

    genMu4eMaildirQueries =
      mail:
      concatStringsSep "\n" (
        map (folder: ''
          ( :name ${toJSON folder.name}
            :query ${toJSON folder.query}
            :source ${toJSON mail.name}
            :bs-hidden t
            :bs-maildir t
            :bs-maildir-key ?${folder.key}
            :maildir ${toJSON folder.path})
        '') (genMu4eMaildirs mail)
      );

    genMu4eMaildirShortcuts =
      mail:
      concatStringsSep "\n" (
        map (folder: ''
          ( :maildir ${toJSON folder.path}
            :key ?${folder.key})
        '') (genMu4eMaildirs mail)
      );

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

        contextQuery = toJSON (genContextQuery mail);

        addresses' = concatStringsSep " " (
          map toJSON mail.addresses
        );

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
           (bs-mu4e-context-name . ${name})
           (bs-mu4e-context-query . ${contextQuery})
           (smime-certificate-directory . ${certdirAbsPath})))
      '';

    genSyncCollections =
      collections:
      concatStringsSep " " (map toJSON collections);
  };

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

          sharedMaildirAddresses = concatLists (
            map mailAddresses sharedMails
          );

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
            concatStringsSep "\n" (
              map genMailContext (
                [ primaryMailEntry ]
                ++ sharedMails
                ++ filter (
                  candidate:
                  !candidate.account.primary
                  && !sharesPrimaryMaildir candidate
                ) enabledMails
              )
            );

          newsGroups = zipAttrsWith (_: concatLists) (
            mapAttrsToList (_: source: source.groups) news
          );

          newsTopics = mapAttrsToList (name: groups: {
            inherit
              groups
              name
              ;
          }) newsGroups;

          newsInitialCatchupGroups = concatLists (
            mapAttrsToList (
              _: source: source.initialCatchupGroups or [ ]
            ) news
          );

          newsMailingLists = concatLists (
            mapAttrsToList (
              _: source:
              mapAttrsToList (group: address: {
                inherit
                  address
                  group
                  ;
              }) (source.mailingLists or { })
            ) news
          );
        in
        with el;
        ''
          (use-package bs-contacts
            :custom
            (bs-contacts-addressbooks '(${genAddressbooks contactAddressbooks}))
            (bs-contacts-default-addressbook '${genDefaultAddressbook contactDefaultAddressbook})
            (bs-contacts-sync-collections '(${genSyncCollections contactSyncCollections}))

            :defer t)

          (use-package bs-khal
            :custom
            (bs-khal-calendar-directories '(${genCalendarDirectories enabledCalendars}))
            (bs-khal-default-calendar ${genDefaultCalendarName enabledCalendars})

            :defer t)

          (use-package bs-gnus
            :custom
            (bs-gnus-group-source-names '(${genGnusSourceNames}))

            :defer t)

          (use-package emacs
            :custom
            (user-full-name "${primaryMail.account.realName}")

            :demand t
            :no-require t)

          (use-package emacs
            :when (display-graphic-p)

            :config
            (set-fontset-font t 'cjk-misc (font-spec :family ${cjkFont}))
            (set-fontset-font t 'han (font-spec :family ${cjkFont}))

            :demand t
            :no-require t)

          (use-package epa-hook
            :config
            (add-to-list 'epa-file-encrypt-to "${primaryMail.account.gpg.key}")

            :defer t)

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

          (use-package gnus
            :defines (gnus-level-default-subscribed
                      gnus-select-method
                      gnus-setup-news-hook
                      gnus-topic-alist
                      gnus-topic-topology)
            :functions (gnus-activate-group
                        gnus-get-info
                        gnus-group-catchup
                        gnus-group-real-name
                        gnus-group-set-subscription
                        gnus-topic-find-topology
                        gnus-topic-sort-topics-1)

            :init
            ${genGnusPreset newsTopics newsInitialCatchupGroups}

            :custom
            (gnus-parameters
             (append
              '(("\\`\\(?:comp\\.\\|nntp\\+gmane:\\)"
                 (display . 100))
                ("\\`comp\\."
                 (agent-predicate . short))
                ("\\`nntp\\+gmane:"
                 (agent-predicate . false))
                ("\\`nntp\\+olduse:"
                 (agent-predicate . true)))
              (mapcar
               (lambda (entry)
                 (list
                  (concat
                   "\\`"
                   (regexp-quote (car entry))
                   "\\'")
                  (cons 'to-list (cdr entry))
                  '(subscribed . t)))
               '(${genGnusMailingLists newsMailingLists}))))

            (gnus-secondary-select-methods nil)

            :hook
            (gnus-setup-news-hook . gnus--preset-setup)

            :config
            (setq gnus-select-method '${genGnusMethod})

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
          agent-recall
          agent-review
          agent-shell
          agent-shell-sidebar
          agent-shell-tramp
          agent-shell-manager
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
          elfeed
          elfeed-org
          elfeed-score
          elfeed-webkit
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

  services = {
    inn = {
      expectedGroupCount = length (
        concatLists (
          mapAttrsToList
            (
              _: source: concatLists (attrValues source.groups)
            )
            (filterAttrs (_: source: source ? endpoint) news)
        )
      );

      upstreams =
        mapAttrs
          (
            _: source:
            {
              inherit (source)
                endpoint
                ;

              groups = concatLists (attrValues source.groups);
            }
            // optionalAttrs (source ? passwordCredential) {
              inherit (source)
                passwordCredential
                username
                ;
            }
          )
          (filterAttrs (_: source: source ? endpoint) news);
    };
  };
}
