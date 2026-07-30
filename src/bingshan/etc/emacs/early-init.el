;;; early-init.el --- Early Init File -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2026 Bingshan Chang <chang@bingshan.org>

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file is load before normal init file is loaded.

;;; Code:

(require 'bs-ext)
(require 'bs-lib)
(require 'seq)
(require 'use-package)



;;
;; use-package (info "(use-package) Top")
;;

(use-package use-package
  :custom
  ;; Defer loading of all packages by default.  Each package declared
  ;; with `use-package' will be loaded lazily unless explicitly marked
  ;; otherwise, reducing startup time and making load order explicit.
  (use-package-always-defer t)

  ;; Do not append a suffix to automatically generated hook variable
  ;; names.  This preserves the original hook names without
  ;; modification and avoids implicit renaming.
  (use-package-hook-name-suffix nil)

  ;; Collect and compute loading statistics for `use-package'
  ;; declarations.  This enables post-startup analysis of package load
  ;; times and deferred execution behavior.
  (use-package-compute-statistics t)

  ;; Disable automatic package installation via `use-package'.
  ;; Setting the ensure function to `ignore' prevents `use-package'
  ;; from invoking any package manager, making package availability an
  ;; explicit responsibility of the surrounding system configuration.
  (use-package-ensure-function 'ignore))



;;
;; Early Initialization (info "(emacs) Early Init File")
;;

(use-package emacs
  :demand t
  :no-require t

  :custom
  ;; Temporarily increase GC threshold during startup.
  (gc-cons-threshold most-positive-fixnum)

  ;; Don't use precious startup time to check mtimes on elisp
  ;; bytecode. Although stale byte-code will heavily impact startup
  ;; times, performance is unimportant when Emacs is in an error
  ;; state.
  (load-prefer-newer noninteractive)

  :hook
  (emacs-startup-hook
   .
   (lambda ()
     ;; Restore to normal value after startup (e.g. 100MiB)
     (let ((threshold (* 100 1024 1024)))
       (set-default-toplevel-value 'gc-cons-threshold threshold)))))

(use-package emacs
  :unless (or (daemonp) noninteractive)
  :demand t
  :no-require t

  :init
  ;; Keep the initial file name handler.
  (put 'file-name-handler-alist
       'initial-value
       file-name-handler-alist)

  ;; Reduce the number of suffixes supported by file name handler
  ;; during the startup to save overhead.
  (set-default-toplevel-value 'file-name-handler-alist nil)

  :hook
  (emacs-startup-hook
   .
   (lambda ()
     ;; Merge the default `file-name-handler-alist' to restore default
     ;; file handlers.
     (let* ((init (get 'file-name-handler-alist 'initial-value))
            (new file-name-handler-alist)
            (v (delete-dups (append init new))))
       (set-default-toplevel-value 'file-name-handler-alist v)))))

(use-package emacs
  :unless noninteractive
  :demand t
  :no-require t
  :custom
  ;; Avoid window resizing caused by font changes at the startup.
  (frame-inhibit-implied-resize t))

(use-package comp
  :init
  ;; After Emacs 28.1, native compilation is available.  It looks for
  ;; the first entry of `native-comp-eln-load-path', which holds the
  ;; compiled .eln files to speed up startup and execution.  We want
  ;; the eln-cache to live in our cache directory (by default the
  ;; eln-cache subdirectory under `user-emacs-directory'), so we
  ;; replace its first element with our custom path.
  (setcar native-comp-eln-load-path
          (bs-path bs-cache-directory "eln-cache/")))

(use-package frame
  :config
  ;; We want to disable various UI elements in every new frame, Menu
  ;; Bar, Tool Bar, Horizontal and Vertical Scroll Bars.  By adding
  ;; these settings to `default-frame-alist', each frame we open will
  ;; start without those elements, giving a cleaner, distraction-free
  ;; interface and more room for our buffers.
  (setq-default default-frame-alist
                (seq-uniq (append default-frame-alist
                                  '((height . 40)
                                    (menu-bar-lines . 0)
                                    (tool-bar-lines . 0)
                                    (vertical-scroll-bars . 0)
                                    (width . 80))))))



;;
;; Emacs Lisp Packages (info "(emacs) Packages")
;;

(use-package package
  :custom
  ;; `package-user-dir' is where Emacs downloads and installs
  ;; packages, default is the elpa subdirectory under
  ;; `user-emacs-directory'.  We override it to live under our data
  ;; directory, name-spaced by `emacs-version', so that each Emacs
  ;; version keeps its own isolated set of packages.
  (package-user-dir (bs-path bs-data-directory emacs-version))

  ;; Ensure verification data is also version-specific.
  (package-gnupghome-dir (bs-path package-user-dir "gnupg/"))

  ;; Emacs writes optimized autoloads into `package-quickstart-file',
  ;; we want that autoload file to live alongside our installed
  ;; packages.
  (package-quickstart-file (bs-path package-user-dir "autoloads.el"))
  (package-quickstart t))

;;; early-init.el ends here
;; Local Variables:
;; fill-column: 70
;; indent-tabs-mode: nil
;; sentence-end-double-space: t
;; tab-width: 2
;; End:
