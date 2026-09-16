;;; gnus-init.el --- Gnus configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Gnus loads this file through `gnus-init-file' before opening
;; servers.  Topic declarations determine the native subscriptions.
;; Apply them after reading saved state to retain read ranges and
;; article marks.

;;; Code:

(require 'cl-lib)
(require 'gnus-group)
(require 'gnus-msg)
(require 'gnus-start)
(require 'gnus-sum)
(require 'gnus-topic)
(require 'subr-x)

(setq gnus-select-method
      '(nntp "local"
             (nntp-address "127.0.0.1")
             (nntp-port-number 1119)
             (nntp-open-connection-function
              nntp-open-network-stream)))

(setq gnus-secondary-select-methods nil)

;; Use dedicated TLS posting methods for the declared Usenet groups.
;; Resolve credentials through `auth-source' when opening a
;; connection.
(setq gnus-post-method-alist
      (mapcar
       (lambda (entry)
         (let ((server (car entry))
               (groups (cdr entry)))
           `(,(concat "\\`" (regexp-opt groups) "\\'")
             nntp ,server
             (nntp-address ,server)
             (nntp-port-number 563)
             (nntp-open-connection-function nntp-open-tls-stream)
             (nntp-authinfo-force t))))
       '(("news.eternal-september.org"
          "comp.arch.fpga"
          "alt.folklore.computers"
          "alt.peeves"
          "comp.emacs"
          "rec.food.drink.tea"
          "rec.games.video.classic"
          "alt.comp.lang.rust"
          "comp.lang.c"
          "comp.lang.c++"
          "comp.lang.haskell"
          "comp.lang.lisp"
          "comp.lang.scheme"
          "comp.os.linux.networking"
          "rec.music.makers.synth"
          "rec.arts.books"
          "comp.security.ssh")
         ("news.solani.org"
          "comp.arch"
          "alt.callahans"
          "gnu.emacs.gnus"
          "rec.arts.movies.current-films"
          "rec.arts.movies.past-films"
          "rec.games.trivia"
          "comp.lang.forth"
          "comp.programming"
          "comp.os.linux.misc"
          "rec.music.classical.recordings"
          "rec.music.misc"
          "rec.music.rock-pop-r+b.1950s"
          "rec.arts.sf.written"
          "sci.astro"
          "comp.security.unix"
          "comp.unix.programmer"))))

(setq gnus-parameters
      (append
       '(("\\`\\(?:comp\\.\\|gmane\\.\\)" (display . 100))
         ("\\`comp\\." (agent-predicate . short)))
       (mapcar
        (lambda (entry)
          (list (concat "\\`" (regexp-quote (car entry)) "\\'")
                (cons 'to-list (cdr entry))
                '(subscribed . t)))
        '(("gmane.comp.gcc.devel" . "gcc@gcc.gnu.org")
          ("gmane.comp.gdb.devel" . "gdb@sourceware.org")
          ("gmane.comp.gnu.binutils" . "binutils@sourceware.org")
          ("gmane.comp.hardware.riscv.isa.devel"
           . "isa-dev@groups.riscv.org")
          ("gmane.comp.hardware.riscv.opensbi.devel"
           . "opensbi@lists.infradead.org")
          ("gmane.comp.kde.devel.general" . "kde-devel@kde.org")
          ("gmane.comp.lib.glibc.alpha" . "libc-alpha@sourceware.org")
          ("gmane.emacs.devel" . "emacs-devel@gnu.org")
          ("gmane.emacs.help" . "help-gnu-emacs@gnu.org")
          ("gmane.linux.ports.riscv"
           . "linux-riscv@lists.infradead.org")
          ("gmane.lisp.asdf.devel"
           . "asdf-devel@lists.common-lisp.net")
          ("gmane.lisp.guile.devel" . "guile-devel@gnu.org")
          ("gmane.lisp.guile.user" . "guile-user@gnu.org")
          ("gmane.lisp.scheme.chez" . "chez-scheme@googlegroups.com")
          ("gmane.lisp.scheme.mit-scheme.devel"
           . "mit-scheme-devel@gnu.org")))))

;; Generate Mail-Followup-To using the declared mailing-list
;; membership.
(setq message-subscribed-address-functions
      '(gnus-find-subscribed-addresses))

(defconst gnus-init-topics
  '(("Architecture"
     "comp.arch.fpga"
     "net.arch"
     "comp.arch")
    ("Conversation"
     "alt.folklore.computers"
     "alt.peeves"
     "net.general"
     "alt.callahans")
    ("Emacs"
     "comp.emacs"
     "gmane.emacs.devel"
     "gmane.emacs.help"
     "net.emacs"
     "gnu.emacs.gnus")
    ("Film"
     "net.movies"
     "rec.arts.movies.current-films"
     "rec.arts.movies.past-films")
    ("Food"
     "rec.food.drink.tea")
    ("Games"
     "rec.games.video.classic"
     "net.games.trivia"
     "net.games.video"
     "rec.games.trivia")
    ("Languages"
     "alt.comp.lang.rust"
     "comp.lang.c"
     "comp.lang.c++"
     "comp.lang.haskell"
     "comp.lang.lisp"
     "comp.lang.scheme"
     "gmane.lisp.asdf.devel"
     "gmane.lisp.guile.devel"
     "gmane.lisp.guile.user"
     "gmane.lisp.scheme.chez"
     "gmane.lisp.scheme.mit-scheme.devel"
     "net.lang.c"
     "net.lang.c++"
     "net.lang.forth"
     "net.lang.lisp"
     "comp.lang.forth"
     "comp.programming")
    ("Linux"
     "comp.os.linux.networking"
     "gmane.comp.kde.devel.general"
     "comp.os.linux.misc")
    ("Local"
     "nndraft:delayed"
     "nndraft:drafts"
     "nndraft:queue")
    ("Music"
     "rec.music.makers.synth"
     "net.music.classical"
     "net.music.synth"
     "rec.music.classical.recordings"
     "rec.music.misc"
     "rec.music.rock-pop-r+b.1950s")
    ("RISC-V"
     "gmane.comp.hardware.riscv.isa.devel"
     "gmane.comp.hardware.riscv.opensbi.devel"
     "gmane.linux.ports.riscv")
    ("Reading"
     "rec.arts.books"
     "net.books"
     "net.sf-lovers"
     "rec.arts.sf.written")
    ("Science"
     "net.astro"
     "net.space"
     "sci.astro")
    ("Security"
     "comp.security.ssh"
     "net.crypt"
     "comp.security.unix")
    ("Toolchain"
     "gmane.comp.gcc.devel"
     "gmane.comp.gdb.devel"
     "gmane.comp.gnu.binutils"
     "gmane.comp.lib.glibc.alpha"
     "mod.compilers"
     "mod.std.c")
    ("Unix"
     "net.unix"
     "net.unix-wizards"
     "net.usenix"
     "comp.unix.programmer"))
  "Declared topics and groups.
Native groups form the subscription list.
Foreign groups such as drafts participate only in topic assignments.")

(defconst gnus-init-initial-catchup-groups
  '("gmane.comp.kde.devel.general")
  "Groups caught up only when first added to Gnus state.")

(defun gnus-init-subscribe (group)
  "Subscribe to native GROUP, preserving existing read state.
Catch up GROUP only when first added and listed in
`gnus-init-initial-catchup-groups'."
  (let ((info (gnus-get-info group)))
    (condition-case err
        (cond
         (info
          (when (> (gnus-info-level info) gnus-level-subscribed)
            (gnus-group-set-subscription
             group gnus-level-default-subscribed t)))
         ((gnus-activate-group group)
          (gnus-group-set-subscription
           group gnus-level-default-subscribed t)
          (when (member group gnus-init-initial-catchup-groups)
            (gnus-group-catchup group 'all)))
         (t
          (display-warning
           'gnus-init (format "Could not activate %s" group))))
      (error
       (display-warning
        'gnus-init
        (format "Could not subscribe to %s: %s"
                group (error-message-string err)))))))

(defun gnus-init-group-less-p (left right)
  "Return non-nil if LEFT sorts before RIGHT by displayed group name."
  (string-lessp
   (string-remove-prefix "gmane." (gnus-group-real-name left))
   (string-remove-prefix "gmane." (gnus-group-real-name right))))

(defun gnus-init-assign-topic (topic)
  "Apply the group assignment in TOPIC and ensure its topology entry.
TOPIC is a list of the topic name followed by its group names."
  (let* ((name (car topic))
         (entry (or (assoc name gnus-topic-alist)
                    (let ((entry (list name)))
                      (setq gnus-topic-alist
                            (append gnus-topic-alist (list entry)))
                      entry)))
         (groups (append (cdr entry) (copy-sequence (cdr topic)))))
    (setcdr entry
            (sort (delete-dups groups) #'gnus-init-group-less-p))
    (unless (gnus-topic-find-topology name)
      (setcdr gnus-topic-topology
              (append (cdr gnus-topic-topology)
                      (list (list (list name 'visible nil nil))))))))

(defun gnus-init-setup ()
  "Apply declared subscriptions and topics after reading Gnus state."
  (when (and (eq (car gnus-select-method) 'nntp)
             (equal (cadr gnus-select-method) "local"))
    (let* ((all-groups (cl-loop for topic in gnus-init-topics
                                append (copy-sequence (cdr topic))))
           (groups
            (delete-dups
             (cl-remove-if-not #'gnus-group-native-p all-groups))))
      (mapc #'gnus-init-subscribe groups)
      (dolist (group (copy-sequence gnus-group-list))
        (let ((info (gnus-get-info group)))
          (when (and info
                     (gnus-group-native-p group)
                     (not (member group groups))
                     (<= (gnus-info-level info)
                         gnus-level-subscribed))
            (gnus-group-set-subscription
             group gnus-level-default-unsubscribed t))))
      (unless gnus-topic-topology
        (setq gnus-topic-topology '(("Gnus" visible nil nil))))
      (unless (assoc "Gnus" gnus-topic-alist)
        (push '("Gnus") gnus-topic-alist))
      (dolist (entry gnus-topic-alist)
        (setcdr entry
                (cl-remove-if
                 (lambda (group) (member group all-groups))
                 (cdr entry))))
      (mapc #'gnus-init-assign-topic gnus-init-topics)
      (gnus-topic-sort-topics-1 gnus-topic-topology nil))))

;; Keep one stable hook entry when Gnus reloads this file on restart.
(add-hook 'gnus-setup-news-hook #'gnus-init-setup)

(provide 'gnus-init)
;;; gnus-init.el ends here
