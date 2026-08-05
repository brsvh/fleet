;;; gnus.el --- Declarative Gnus subscriptions  -*- lexical-binding: t; -*-

;;; Commentary:

;; Seed the selected groups and their two-level topic layout after
;; Gnus has read its machine-local newsrc state.  Existing local
;; subscription levels, topic assignments, and additional groups take
;; precedence over this preset.

;;; Code:

(require 'gnus)
(require 'gnus-group)
(require 'gnus-start)
(require 'gnus-sum)
(require 'gnus-topic)
(require 'gnus-util)
(require 'subr-x)

(let* ((topics
        '(("Architecture"
           "nntp+olduse:net.arch"
           "nntp+solani:comp.arch"
           "comp.arch.fpga")
          ("Conversation"
           "nntp+solani:alt.callahans"
           "alt.folklore.computers"
           "alt.peeves"
           "nntp+olduse:net.general")
          ("Emacs"
           "comp.emacs"
           "nntp+gmane:gmane.emacs.devel"
           "nntp+gmane:gmane.emacs.help"
           "nntp+olduse:net.emacs"
           "nntp+solani:gnu.emacs.gnus")
          ("Film"
           "nntp+olduse:net.movies"
           "nntp+solani:rec.arts.movies.current-films"
           "nntp+solani:rec.arts.movies.past-films")
          ("Food"
           "rec.food.drink.tea")
          ("Games"
           "nntp+olduse:net.games.trivia"
           "nntp+olduse:net.games.video"
           "nntp+solani:rec.games.trivia"
           "rec.games.video.classic")
          ("Languages"
           "alt.comp.lang.rust"
           "comp.lang.c"
           "comp.lang.c++"
           "nntp+olduse:net.lang.c"
           "nntp+olduse:net.lang.c++"
           "nntp+olduse:net.lang.forth"
           "nntp+olduse:net.lang.lisp"
           "nntp+solani:comp.lang.forth"
           "comp.lang.haskell"
           "comp.lang.lisp"
           "comp.lang.scheme"
           "nntp+solani:comp.programming"
           "nntp+gmane:gmane.lisp.asdf.devel"
           "nntp+gmane:gmane.lisp.guile.devel"
           "nntp+gmane:gmane.lisp.guile.user"
           "nntp+gmane:gmane.lisp.scheme.chez"
           "nntp+gmane:gmane.lisp.scheme.mit-scheme.devel")
          ("Linux"
           "nntp+gmane:gmane.comp.kde.devel.general"
           "nntp+solani:comp.os.linux.misc"
           "comp.os.linux.networking")
          ("Local"
           "nndraft:delayed"
           "nndraft:drafts"
           "nndraft:queue")
          ("Music"
           "nntp+olduse:net.music.classical"
           "nntp+olduse:net.music.synth"
           "nntp+solani:rec.music.classical.recordings"
           "rec.music.makers.synth"
           "nntp+solani:rec.music.misc"
           "nntp+solani:rec.music.rock-pop-r+b.1950s")
          ("RISC-V"
           "nntp+gmane:gmane.comp.hardware.riscv.isa.devel"
           "nntp+gmane:gmane.comp.hardware.riscv.opensbi.devel"
           "nntp+gmane:gmane.linux.ports.riscv")
          ("Reading"
           "nntp+olduse:net.books"
           "nntp+olduse:net.sf-lovers"
           "rec.arts.books"
           "nntp+solani:rec.arts.sf.written")
          ("Science"
           "nntp+olduse:net.astro"
           "nntp+olduse:net.space"
           "nntp+solani:sci.astro")
          ("Security"
           "comp.security.ssh"
           "nntp+olduse:net.crypt"
           "nntp+solani:comp.security.unix")
          ("Toolchain"
           "nntp+gmane:gmane.comp.gcc.devel"
           "nntp+gmane:gmane.comp.gdb.devel"
           "nntp+gmane:gmane.comp.gnu.binutils"
           "nntp+gmane:gmane.comp.lib.glibc.alpha"
           "nntp+olduse:mod.compilers"
           "nntp+olduse:mod.std.c")
          ("Unix"
           "nntp+olduse:net.unix"
           "nntp+olduse:net.unix-wizards"
           "nntp+olduse:net.usenix"
           "nntp+solani:comp.unix.programmer")))
       (initial-catchup-groups
        '("nntp+gmane:gmane.comp.kde.devel.general"))
       (assigned-groups
        (delete-dups
         (apply #'append
                (mapcar
                 (lambda (topic)
                   (copy-sequence (cdr topic)))
                 gnus-topic-alist)))))
  (dolist (group (apply #'append (mapcar #'cdr topics)))
    (unless (or (string-prefix-p "nndraft:" group)
                (gnus-get-info group))
      (condition-case err
          (if (gnus-activate-group group)
              (progn
                (gnus-group-set-subscription
                 group gnus-level-default-subscribed t)
                (when (member group initial-catchup-groups)
                  (gnus-group-catchup group 'all)))
            (display-warning
             'gnus-config
             (format "Could not activate Gnus group %s" group)))
        (error
         (display-warning
          'gnus-config
          (format "Could not subscribe to Gnus group %s: %s"
                  group (error-message-string err)))))))
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
                        (append gnus-topic-alist (list entry)))
                  entry))))
      (dolist (group (cdr topic))
        (unless (member group assigned-groups)
          (setcdr entry (append (cdr entry) (list group)))
          (push group assigned-groups)))
      (setcdr entry
              (sort
               (delete-dups (cdr entry))
               (lambda (left right)
                 (string-lessp
                  (string-remove-prefix
                   "gmane." (gnus-group-real-name left))
                  (string-remove-prefix
                   "gmane." (gnus-group-real-name right))))))
      (unless (gnus-topic-find-topology name)
        (setcdr gnus-topic-topology
                (append
                 (cdr gnus-topic-topology)
                 (list
                  (list (list name 'visible nil nil))))))))
  (gnus-topic-sort-topics-1 gnus-topic-topology nil))

;;; gnus.el ends here
