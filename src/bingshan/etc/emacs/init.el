;;; init.el --- User Init File -*- lexical-binding: t; -*-

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

;; This file is the first loaded file after Emacs is started.

;;; Code:

(require 'bs-ext)
(require 'bs-hooks)
(require 'bs-lib)
(require 'cl-lib)
(require 'orderless)
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

  ;; Collect and compute loading statistics for `use-package'
  ;; declarations.  This enables post-startup analysis of package load
  ;; times and deferred execution behavior.
  (use-package-compute-statistics t)

  ;; Disable automatic package installation via `use-package'.
  ;; Setting the ensure function to `ignore' prevents `use-package'
  ;; from invoking any package manager, making package availability an
  ;; explicit responsibility of the surrounding system configuration.
  (use-package-ensure-function 'ignore)

  ;; Do not append a suffix to automatically generated hook variable
  ;; names.  This preserves the original hook names without
  ;; modification and avoids implicit renaming.
  (use-package-hook-name-suffix nil))

;;
;; The Organization of the Screen (info "(emacs) Screen")
;;

(use-package doom-modeline
  :custom
  ;; Avoid dedicating vertical space to a rich modeline when the
  ;; window is too narrow, so limited screen width remains focused on
  ;; buffer content rather than status decoration.
  (doom-modeline-window-width-limit 80)

  ;; Keep numeric information in the modeline visually simple and
  ;; unambiguous, avoiding decorative glyphs that may reduce clarity
  ;; or consistency across fonts and environments.
  (doom-modeline-unicode-number nil)

  :hook
  ;; Establish the enhanced modeline as part of the normal UI once the
  ;; graphical interface is ready, rather than during early startup.
  (bs-first-ui-hook . doom-modeline-mode))

(use-package doom-modeline-core
  :after (doom-modeline)
  :functions (doom-modeline-remove-segment)

  :config
  ;; Remove the left-edge status bar from every built-in modeline
  ;; template so the layout stays text-focused and visually quieter.
  (doom-modeline-remove-segment 'bar 'all))

(use-package menu-bar
  :after (bs-hooks)
  :commands (menu-bar-mode)

  :hook
  ;; Disable the Menu Bar for all frames once the UI is initialized.
  (bs-first-ui-hook . (lambda () (menu-bar-mode -1))))

(use-package spacious-padding
  :after (bs-hooks)
  :commands (spacious-padding-mode)

  :custom
  ;; Replace filled mode/header line backgrounds with thin
  ;; overlines/underlines that use the dedicated Spacious Padding
  ;; faces, while preserving the configured padding.
  (spacious-padding-subtle-frame-lines
   '( :mode-line-active spacious-padding-line-active
      :mode-line-inactive spacious-padding-line-inactive
      :header-line-active spacious-padding-line-active
      :header-line-inactive spacious-padding-line-inactive))

  :hook
  ;; Enable Spacious Padding once the graphical interface is ready, so
  ;; the additional frame and window spacing is applied with the rest
  ;; of the UI setup.
  (bs-first-ui-hook . spacious-padding-mode))

(use-package spacious-padding
  :when (eq window-system 'pgtk)

  :custom
  ;; Keep PGTK frame chrome compact by using narrower border, fringe,
  ;; scroll-bar, and tab-bar widths while preserving the shared
  ;; mode/header/tab-line padding.
  (spacious-padding-widths '( :custom-button-width 4
                              :fringe-width 8
                              :header-line-width 4
                              :internal-border-width 2
                              :mode-line-width 4
                              :right-divider-width 0
                              :scroll-bar-width 12
                              :tab-bar-width 8
                              :tab-line-width 4
                              :tab-width 4)))

(use-package spacious-padding
  :when (eq window-system 'x)

  :custom
  ;; Use wider X frame chrome widths than the PGTK configuration while
  ;; keeping the text-adjacent mode/header/tab-line padding aligned
  ;; with the shared layout.
  (spacious-padding-widths '( :custom-button-width 4
                              :fringe-width 12
                              :header-line-width 4
                              :internal-border-width 4
                              :mode-line-width 4
                              :right-divider-width 0
                              :scroll-bar-width 24
                              :tab-bar-width 16
                              :tab-line-width 4
                              :tab-width 4)))

(use-package tool-bar
  :after (bs-hooks)
  :commands (tool-bar-mode)

  :hook
  ;; Disable the tool bar for all frames once the UI is initialized.
  (bs-first-ui-hook . (lambda () (tool-bar-mode -1))))

;;
;; Entering Emacs (info "(emacs) Entering Emacs")
;;

(use-package startup
  :demand t
  :no-require t

  :custom
  ;; Use a simple initial Major Mode to avoid heavy loading overhead.
  (initial-major-mode 'fundamental-mode)

  ;; Let Emacs skip the initial splash screen and splash message on
  ;; startup, so we can taken directly to our editing buffer without
  ;; any introductory distractions.
  (inhibit-startup-screen t))

;;
;; Exiting Emacs (info "(emacs) Exiting")
;;

;;
;; Basic Editing Commands (info "(emacs) Basic")
;;

(use-package consult
  :bind
  ( :map goto-map
    ;; Go to matched file.
    ("f" . consult-find)

    ;; Go to matched grep search result.
    ("g" . consult-grep)

    ;; Go to line matches entered string.
    ("l" . consult-line)

    ;; Go to matched ripgrep search result.
    ("r" . consult-ripgrep)))

(use-package mwim
  :bind
  ( :map global-map
    ;; Remap `move-beginning-of-line' globally to
    ;; `mwim-beginning-of-code-or-line'.  The command first moves to
    ;; the first non-whitespace character of the line, and if already
    ;; there, moves to the true beginning of the line.  This preserves
    ;; the original command’s intent while adding context-aware
    ;; behavior.
    ([remap move-beginning-of-line] . mwim-beginning-of-code-or-line)

    ;; Remap `move-end-of-line' globally to
    ;; `mwim-end-of-code-or-line'.  The command first moves to the end
    ;; of code on the line (before trailing whitespace or comments),
    ;; and if already there, moves to the actual end of the line.
    ([remap move-end-of-line] . mwim-end-of-code-or-line)))

(use-package simple
  :after (bs-hooks)

  :hook
  ;; Display the current Column number.
  (bs-first-buffer-hook . column-number-mode)

  ;; Display the current Line number.b
  (bs-first-buffer-hook . line-number-mode))

;;
;; The Minibuffer (info "(emacs) Minibuffer")
;;

(use-package cape
  :after (minibuffer)

  :bind-keymap
  ;; Bind `cape' prefix keymap providing all Cape commands under a
  ;; mnemonic key.
  ("M-p" . cape-prefix-map))

(use-package consult
  :commands (consult-completion-in-region))

(use-package corfu
  :after (vertico)
  :commands (corfu-mode)
  :defines (read-passwd-map)

  :hook
  (minibuffer-setup-hook
   .
   (lambda ()
     ;; Enable Corfu in the mini-buffer for CAPF-style in-region
     ;; completion, but avoid interfering with completing-read UI
     ;; (Vertico/MCT) and sensitive input prompts (e.g. password
     ;; entry).
     (unless (or (bound-and-true-p mct--active)
                 (bound-and-true-p vertico--input)
                 (eq (current-local-map) read-passwd-map))
       (corfu-mode +1)))))

(use-package emacs
  :demand t
  :no-require t

  :custom
  ;; Allow nested mini buffers.
  (enable-recursive-minibuffers t)

  ;; Drop duplicated history.
  (history-delete-duplicates t)

  ;; Prefer to use `y-or-n-p' to confirm the interactive commands
  ;; requires reconfirmation.
  (use-short-answers t))

(use-package embark
  :custom
  ;; Pop up embark buffers below the current buffer.
  (embark-verbose-indicator-display-action
   '(display-buffer-reuse-window display-buffer-below-selected))

  :config
  ;; Show the transient Embark action menu in a dedicated bottom side
  ;; window so action discovery stays visible without replacing the
  ;; current editing window.
  (add-to-list 'display-buffer-alist
               '("\\*Embark Actions\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))
                 (window-height . fit-window-to-buffer)))

  ;; Place Embark collect buffers in a persistent side window on the
  ;; right so live candidate views remain inspectable while the main
  ;; window keeps focus on the current task.
  (add-to-list 'display-buffer-alist
               '((derived-mode . embark-collect-mode)
                 (display-buffer-reuse-mode-window
                  display-buffer-in-side-window)
                 (preserve-size . (t . t))
                 (side . right)
                 (window-width . 0.35)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))))

  :bind
  ( :map global-map
    ;; Quick action at point by press \\`C-.'
    ("C-." . embark-act)

    ;; Run default action at point by press \\`C-;'.
    ("C-;" . embark-dwim)

    :map help-map
    ;; Use `embark-bindings' to list keys.
    ("B" . embark-bindings)))

(use-package marginalia
  :after (bs-hooks)

  :custom
  ;; Display marginalia at right.
  (marginalia-align 'right)

  :hook
  ;; Show marginalia of the mini-buffer completions.
  (bs-first-ui-hook . marginalia-mode))

(use-package minibuffer
  :custom
  ;; Use mini-buffer completion as the UI for ‘completion-at-point’.
  (completion-in-region-function 'consult-completion-in-region)

  ;; Setup our preferred completion styles:
  ;;
  ;; * substring:          bar    -> foo-bar-baz
  ;; * orderless:          f b b  -> foo-bar-baz
  ;; * basic:              fo     -> foo-bar-baz
  ;; * partial-completion: -bar-b -> foo-bar-baz
  (completion-styles '(orderless basic))

  ;; Disable default completion styles.
  (completion-category-defaults nil)

  ;; Override category-specific completion styles.
  (completion-category-overrides
   '((file (styles partial-completion))))

  ;; Let partial-completion behaves as if each word is preceded by
  ;; wildcard.
  (completion-pcm-leading-wildcard t))

(use-package savehist
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (savehist-file (bs-path bs-state-directory "history.el"))

  :hook
  ;; Persist our mini-buffer history.
  (bs-first-ui-hook . savehist-mode))

(use-package orderless
  :custom
  ;; Allow escape with the black-splash.
  (orderless-component-separator 'orderless-escapable-split-on-space))

(use-package switch-window
  :after (embark)

  :config
  ;; Exclude Embark collect helper windows from `switch-window' so
  ;; window selection targets only primary work buffers.
  (add-to-list 'switch-window-ignore-rules
               '(:mode embark-collect-mode)))

(use-package vertico
  :after (bs-hooks)

  :custom
  ;; Resize the Vertico buffer size when the number of candidates
  ;; changed.
  (vertico-resize t)

  ;; Return to the top of the candidates when reaching the bottom of
  ;; candidates.
  (vertico-cycle t)

  :hook
  ;; Use the vertical interactive completion by default.
  (bs-first-ui-hook . vertico-mode))

(use-package vertico-directory
  :after (:all rfn-eshadow vertico)

  :bind
  ( :map vertico-map
    ;; Enter current candidate when press \\`<return>'.
    ("<return>" . vertico-directory-enter)

    ;; Delete char or directories before point when press
    ;; \\`<backspace>'.
    ("<backspace>" . vertico-directory-delete-char)
    ("DEL" . vertico-directory-delete-char)

    ;; Delete word or directories before point when press
    ;; \\`M-<backspace>'.
    ("M-<backspace>" . vertico-directory-delete-word)
    ("M-DEL" . vertico-directory-delete-word))

  :hook
  ;; Tidy shadowed file names.
  (rfn-eshadow-update-overlay-hook . vertico-directory-tidy))

(use-package vertico-mouse
  :after (vertico)

  :hook
  ;; Enable mouse support for `vertico-mode'.
  (vertico-mode-hook . vertico-mouse-mode))

(use-package winner
  :after embark
  :config
  ;; Ignore embark buffers when undo/redo window layout.
  (add-to-list 'winner-boring-buffers "*Embark Collect Completions*" t)
  (add-to-list 'winner-boring-buffers "*Embark Collect Live*" t))

;;
;; Running Commands by Name (info "(emacs) M-x")
;;

(use-package simple
  :custom
  ;; Only show available commands in current mode.
  (read-extended-command-predicate
   'command-completion-default-include-p))

;;
;; Help (info "(emacs) Help")
;;

(use-package embark
  :commands (embark-prefix-help-command)

  :custom
  ;; Use `embark-prefix-help-command' to provide the help prompt of
  ;; prefix commands.
  (prefix-help-command 'embark-prefix-help-command))

(use-package help-fns
  :after (help)

  :bind
  ( :map help-map
    ;; Describe a given keymap when press \\`C-h C-k'.
    ("C-k" . describe-keymap)))

(use-package help-mode
  :after (window)

  :config
  ;; Add a display buffer rule to make Help buffers shown in a side
  ;; window at the bottom of the frame with its height set to 40% of
  ;; the total frame height.
  (add-to-list 'display-buffer-alist
               '((derived-mode . help-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.35))))

;;
;; The Mark and the Region (info "(emacs) Mark")
;;

(use-package delsel
  :after (bs-hooks)

  :hook
  ;; When typing with a selected region, replace it directly.
  (bs-first-buffer-hook . delete-selection-mode))

;;
;; Killing and Moving Text (info "(emacs) Killing")
;;

(use-package consult
  :bind
  ( :map global-map
    ;; Remap the built-in `yank' command globally to
    ;; `consult-yank-from-kill-ring' which provides an interactive UI
    ;; to select an entry from the kill ring before inserting it,
    ;; while preserving the same keybinding entry point.
    ([remap yank] . consult-yank-from-kill-ring)

    ;; Remap the built-in `yank-pop' command globally to
    ;; `consult-yank-pop' which replaces the default cycling behavior
    ;; with a Consult-based selection interface over the kill ring,
    ;; keeping the original command semantics (replace the last yanked
    ;; text) but changing the UI.
    ([remap yank-pop] . consult-yank-pop)))

(use-package select
  :custom
  ;; Enable integration with the system clipboard.
  (select-enable-clipboard t))

(use-package simple
  :custom
  ;; Inhibit duplicated contents to kill ring.
  (kill-do-not-save-duplicates t)

  ;; Sync kill ring to the system clipboard.
  (save-interprogram-paste-before-kill t))

;;
;; Registers (info "(emacs) Registers")
;;

(use-package bookmark
  :after (bs-lib)

  :custom
  ;; Store bookmarks in our data directory.
  (bookmark-default-file (bs-path bs-data-directory "bookmarks.el")))

(use-package consult
  :bind
  ( :map global-map
    ;; Replace default bookmark list command with `consult-bookmark'.
    ([remap bookmark-bmenu-list] . consult-bookmark)))

;;
;; Controlling the Display (info "(emacs) Display")
;;

(use-package display-fill-column-indicator
  :after (prog-mode)

  :hook
  ;; Display an indication of the `fill-column' position.
  (prog-mode-hook . display-fill-column-indicator-mode))

(use-package display-line-numbers
  :after (prog-mode)

  :hook
  ;; Show line numbers.
  (prog-mode-hook . display-line-numbers-mode))

(use-package emacs
  :demand t
  :no-require t

  :custom
  ;; Inhibit automatically adjust the window's vertical position to
  ;; keep point centered vertically.
  (auto-window-vscroll nil)

  ;; Let Emacs prioritize speed over precise scrolling.
  (fast-but-imprecise-scrolling t)

  ;; Allow the pointer can move directly to the left or right edge of
  ;; the window.
  (hscroll-margin 2)

  ;; Smoother and less disruptive horizontal scrolling.
  (hscroll-step 1)

  ;; Smoother and less disruptive scrolling, never recenter the
  ;; pointer when it moves off-screen.
  (scroll-conservatively 10)

  ;; Let the pointer can move directly to the top or bottom edge of
  ;; the window.
  (scroll-margin 0)

  ;; Enable category-based line breaking for word wrapping.
  (word-wrap-by-category t))

(use-package hl-line
  :after (prog-mode)

  :hook
  ;; Highlight the current line.
  (prog-mode-hook . hl-line-mode))

(use-package modus-themes
  :after (bs-hooks)
  :commands (modus-themes-select)

  :custom
  ;; Disable all other themes when loading a Modus Theme.
  (modus-themes-disable-other-themes t)

  ;;Use bold for code syntax highlighting and related.
  (modus-themes-bold-constructs t)

  ;; Use italics for code syntax highlighting and related.
  (modus-themes-italic-constructs t)

  ;; Themes we used.
  (modus-themes-to-toggle '(modus-operandi-tinted
                            modus-vivendi-tinted))

  ;; Use `fixed-pitch' face for Org tables and code blocks.
  (modus-themes-mixed-fonts t)

  ;; Use bold prompts.
  (modus-themes-prompts '(bold))

  ;; Change boldness of completion faces.
  (modus-themes-completions '((matches . (extrabold))
                              (selection . (semibold italic))))

  ;; Set different font sizes for headings of various levels.
  (modus-themes-headings '((0 . (1.40 ultrabold))
                           (1 . (1.30 extrabold))
                           (2 . (1.20 heavy))
                           (3 . (1.10 bold))
                           (t . (1.05 semibold))))

  ;; Cross-theme modifications.
  (modus-themes-common-palette-overrides
   '(;; Reuse the current-line highlight background for active line
     ;; numbers so the line number column aligns visually with
     ;; `hl-line'.
     (bg-line-number-active bg-hl-line)

     ;; Use the same background for the tab bar and inactive tabs so
     ;; the strip recedes and individual tabs carry the separation.
     (bg-tab-bar bg-tab-other)

     ;; Remove mode line border.
     (border-mode-line-active unspecified)
     (border-mode-line-inactive unspecified)))

  :hook
  (bs-first-ui-hook
   .
   (lambda ()
     ;; Enable the first theme we used, if not set, fallback to
     ;; `modus-operandi-tinted'.
     (modus-themes-select (or (car modus-themes-to-toggle)
                              'modus-operandi-tinted)))))

(use-package whitespace
  :defines (whitespace-line-column)

  :preface
  (defun whitespace--follow-fill-column (&rest _)
    "Keep `whitespace-line-column' in sync with `fill-column'."
    (when (bound-and-true-p whitespace-mode)
      (setq-local whitespace-line-column fill-column)))

  :custom
  ;; Focus whitespace highlighting on cases that tend to indicate
  ;; formatting mistakes or policy violations, so attention is drawn
  ;; to issues that matter during writing and review.
  (whitespace-style '(face
                      lines-tail
                      missing-newline-at-eof
                      space-before-tab
                      trailing))

  :config
  ;; Keep the visual indication of overlong lines aligned with the
  ;; current column policy, so changes to line width expectations are
  ;; reflected immediately in what is highlighted.
  (add-variable-watcher 'fill-column
                        'whitespace--follow-fill-column)

  :hook
  ;; Ensure the visual boundary stays consistent whenever whitespace
  ;; highlighting becomes active.
  (whitespace-mode-hook . whitespace--follow-fill-column))

;;
;; Searching and Replacement (info "(emacs) Search")
;;

(use-package anzu
  :after (bs-hooks)

  :hook
  ;; Get real-time match counts and context search by `anzu-mode'.
  (bs-first-file-hook . global-anzu-mode))

;;
;; Commands for Fixing Typos (info "(emacs) Fixit")
;;

(use-package consult-jinx
  :after (bs-ext)

  :bind
  ( :map ctl-c-map
    ;; Provide a focused, interactive way to review and fix spelling
    ;; issues on demand, so correction happens deliberately instead of
    ;; interrupting normal writing flow.
    ("$" . consult-jinx)))

(use-package jinx
  :config
  ;; Treat CJK Unified Ideographs and their extension blocks as word
  ;; constituents in Jinx's syntax table.  This prevents the spell
  ;; checker from treating East Asian characters as word boundaries,
  ;; avoiding false-positive spelling flags within mixed-language
  ;; text.
  (add-hook 'jinx-mode-hook
            #'(lambda ()
                (defvar jinx--syntax-table)
                (let ((st jinx--syntax-table))
                  (modify-syntax-entry '(#x4E00 . #x9FFF) "_" st)
                  (modify-syntax-entry '(#x3400 . #x4DBF) "_" st)
                  (modify-syntax-entry '(#x20000 . #x2A6DF) "_" st)
                  (modify-syntax-entry '(#x2A700 . #x2B73F) "_" st)
                  (modify-syntax-entry '(#x2B740 . #x2B81F) "_" st)
                  (modify-syntax-entry '(#x2B820 . #x2CEAF) "_" st)
                  (modify-syntax-entry '(#x2CEB0 . #x2EBEF) "_" st)
                  (modify-syntax-entry '(#x30000 . #x3134F) "_" st)
                  (modify-syntax-entry '(#x31350 . #x323AF) "_" st)
                  (modify-syntax-entry '(#x2EBF0 . #x2EE5F) "_" st))))

  :hook
  ;; Establish global spell checking as part of the normal editing
  ;; environment, while deferring activation until after startup to
  ;; minimize initialization overhead.  It will replace the default
  ;; `ispell'.
  (bs-first-buffer-hook . global-jinx-mode))

;;
;; Keyboard Macros (info "(emacs) Keyboard Macros")
;;

;;
;; File Handling (info "(emacs) Files")
;;

(use-package autorevert
  :after (bs-hooks)

  :custom
  ;; Suppress verbose revert messages for a quiet editing experience.
  (auto-revert-verbose nil)

  :hook
  ;; Automatically keep buffers in sync with external file changes.
  (bs-first-file-hook . global-auto-revert-mode))

(use-package consult
  :bind
  ( :map global-map
    ;; Replace `recentf-open' with the better and preview-able
    ;; `consult-recent-file'.
    ([remap recentf-open] . consult-recent-file)))

(use-package editorconfig
  :after (bs-hooks)

  :hook
  ;; Enable `editorconfig-mode' after early startup work completes so
  ;; files opened during normal editing apply project coding style
  ;; settings (such as indentation, charset, and end-of-line rules)
  ;; from `.editorconfig' files.
  (bs-after-startup-early-hook . editorconfig-mode))

(use-package files
  :after (bs-lib)

  :custom
  ;; We enable backups and use copying rather than renaming to
  ;; preserve file links and metadata.
  (make-backup-files t)
  (backup-by-copying t)

  ;; Turn on numbered backups, so Emacs creates multiple versions of
  ;; each file, and automatically prunes excess backups, retaining
  ;; the five oldest and the five most recent versions of each file
  ;; to balance safety with disk usage.
  (version-control t)
  (delete-old-versions t)
  (kept-old-versions 5)
  (kept-new-versions 5)

  ;; Let Emacs create lock-files whenever you open a file, so that if
  ;; another user or Emacs process tries to edit the same file
  ;; simultaneously, we’ll get a warning and avoid accidental
  ;; overwrites or conflicts.
  (create-lockfiles t)

  ;; Enable Emacs’s Auto Saving mechanism by default.
  (auto-save-default t)
  (auto-save-no-message t)

  ;; Emacs treats large text deletions as edits and will trigger an
  ;; auto‐save when they occur.  Disables it to inhibit immediate
  ;; auto‐save when remove large chunks of text, reducing unnecessary
  ;; auto‐save files during big refactors.
  (auto-save-include-big-deletions nil)

  :config
  ;; By default backups go alongside the original files, but to keep
  ;; things tidy we redirect all backups into our data directory’s
  ;; "backup/" sub-folder.  This centralizes backup files (rather than
  ;; littering each project directory) without losing the safety of
  ;; Emacs’ backups.
  (add-to-list 'backup-directory-alist
               `("." . ,(bs-path* bs-data-directory "backup/")))

  ;; Redirects all auto-save files into a dedicated auto-save/ folder
  ;; under our data directory.
  (add-to-list 'auto-save-file-name-transforms
               `(".*" ,(bs-path* bs-data-directory "auto-save/") t)))

(use-package prog-mode
  :after (bs-ext files)

  :hook
  (prog-mode-hook
   .
   (lambda ()
     ;; Always delete trailing when programming.
     (add-hook 'before-save-hook 'bs/delete-trailing-whitespace nil t)

     ;; Do untabify when `indent-tabs-mode' is nil
     (unless indent-tabs-mode
       (add-hook 'before-save-hook 'bs/untabify nil t)))))

(use-package recentf
  :after (:all bs-hooks bs-lib)

  :custom
  ;; Store recent files list in our state directory.
  (recentf-save-file (bs-path bs-state-directory "recent.el"))

  :config
  ;; Silencing all messages during `recentf' loading and cleanup.
  (advice-add 'recentf-load-list :around 'bs-silence-message)
  (advice-add 'recentf-cleanup   :around 'bs-silence-message)

  :hook
  ;; Enable `recentf-mode' to provide the list of recent files.
  (bs-first-file-hook . recentf-mode))

(use-package so-long
  :hook
  ;; Enable protection for newly visited files as soon as normal
  ;; initialization finishes, so command-line file arguments and early
  ;; file visits can still be checked for pathological long lines.
  (after-init-hook . global-so-long-mode))

(use-package switch-window
  :after (treemacs)

  :config
  ;; Keep project navigation panels out of the interactive window
  ;; selection flow, so window switching focuses on editing contexts
  ;; rather than fixed utility sidebars.
  (add-to-list 'switch-window-ignore-rules '(:mode treemacs-mode)))

(use-package treemacs
  :config
  ;; Treat Treemacs as a persistent project sidebar rather than a
  ;; transient buffer, anchoring it to a fixed location so spatial
  ;; memory can be built around the file tree.
  (add-to-list 'display-buffer-alist
               '((derived-mode . treemacs-mode)
                 (display-buffer-reuse-mode-window
                  display-buffer-in-side-window)
                 (preserve-size . (t . t))
                 (side . left)
                 (slot . -1)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))))

  :bind
  ( :map ctl-c-f-map
    ;; Press \\`C-c f b' to find bookmark.
    ("b" . treemacs-bookmark)

    ;; Press \\`C-c f d' to open the specified directory in the
    ;; Treemacs window.
    ("d" . treemacs-select-directory)

    ;; Press \\`C-c f f' to focus the current file in the Treemacs
    ;; window.
    ("f" . treemacs-find-file)

    ;; The primary entry.
    ("t" . treemacs)

    ;; Focus to the Treemacs window.
    ("s" . treemacs-select-window)))

(use-package treemacs-customiztion
  :custom
  ;; Favor a dense tree representation to maximize information within
  ;; limited horizontal space.
  (treemacs-indentation 1)

  ;; Prevent Treemacs from participating in normal window selection,
  ;; reinforcing its role as a fixed navigation panel rather than an
  ;; editing target.
  (treemacs-is-never-other-window t)

  ;; Include hidden files in the tree to reflect the complete project
  ;; structure instead of an opinionated subset.
  (treemacs-show-hidden-files t)

  ;; Persist Treemacs state across sessions so project context
  ;; survives restarts and remains stable over time.
  (treemacs-persist-file (bs-path bs-state-directory
                                  "treemacs/state"))
  (treemacs-last-error-persist-file (bs-path bs-state-directory
                                             "treemacs/error"))

  ;; Keep the project tree consistently positioned on the left to
  ;; support spatial navigation habits.
  (treemacs-position 'left)

  ;; Reduce background noise by suppressing non-essential refresh and
  ;; file-watch messages.
  (treemacs-silent-refresh t)
  (treemacs-silent-filewatch t))

(use-package treemacs-filewatch-mode
  :after (treemacs)
  :commands (treemacs-filewatch-mode)

  :init
  ;; Keep the project tree reflecting file-system changes in real
  ;; time, so Treemacs can be relied on as an accurate representation
  ;; of the current project state during navigation and refactoring.
  (treemacs-filewatch-mode +1))

(use-package treemacs-follow-mode
  :after (treemacs)
  :commands (treemacs-follow-mode)

  :init
  ;; Keep the tree aligned with the current editing context, allowing
  ;; quick orientation within large projects.
  (treemacs-follow-mode +1))

(use-package treemacs-nerd-icons
  :after (treemacs)
  :commands (treemacs-nerd-icons-config)

  :init
  ;; Use iconography to make file roles and types recognizable at a
  ;; glance, reducing the need to parse filenames while navigating.
  (treemacs-nerd-icons-config))

(use-package treemacs-scope
  :after (treemacs treemacs-tab-bar)
  :commands (treemacs-set-scope-type)

  :config
  ;; Scope Treemacs to tabs, treating each tab as an independent
  ;; workspace with its own navigation state.
  (treemacs-set-scope-type 'Tabs))

(use-package treemacs-tab-bar
  :after (treemacs)

  ;; Align the Treemacs instance with tab-based workflows, so each tab
  ;; maintains its own project context instead of sharing a single
  ;; global tree across unrelated tasks.
  :demand t)

;;
;; Using Multiple Buffers (info "(emacs) Buffers")
;;

(use-package consult
  :bind
  ( :map global-map
    ;; Take a peep when switch to other buffer.
    ([remap switch-to-buffer] . consult-buffer)

    ;; Take a peep when switch to buffer in other window.
    ([remap switch-to-buffer-other-window]
     .
     consult-buffer-other-window)

    ;; Take a peep when switch to buffer in other frame.
    ([remap switch-to-buffer-other-frame]
     .
     consult-buffer-other-frame)))

(use-package ibuffer
  :bind
  ( :map global-map
    ;; Use `ibuffer' when list buffers.
    ([remap list-buffers] . ibuffer)))

(use-package ibuffer-project
  :after (ibuffer)
  :commands (ibuffer-do-sort-by-project-file-relative
             ibuffer-project-generate-filter-groups)

  :custom
  ;; Avoid calling `project-current' each time.
  (ibuffer-project-use-cache t)

  :hook
  (ibuffer-hook
   .
   (lambda ()
     ;; Organize buffers around project boundaries so related files
     ;; are viewed and managed together, making it easier to reason
     ;; about ongoing work without relying on buffer names or manual
     ;; grouping.
     (setq ibuffer-filter-groups
           (ibuffer-project-generate-filter-groups))

     ;; Favor a stable, project-relative ordering that reflects how
     ;; files relate to each other on disk, supporting quick scanning
     ;; and navigation within large buffer sets.
     (unless (eq ibuffer-sorting-mode 'project-file-relative)
       (ibuffer-do-sort-by-project-file-relative)))))

(use-package nerd-icons-ibuffer
  :after (ibuffer)

  :hook
  ;; Use visual cues to speed up buffer triage, not to decorate the
  ;; buffer list.
  (ibuffer-mode-hook . nerd-icons-ibuffer-mode))

(use-package uniquify
  :custom
  ;; Use `forward' style.
  ;;
  ;; The files ‘/foo/bar/mumble/name’ and ‘/baz/quux/mumble/name’
  ;; will have follow name.
  ;;
  ;;  bar/mumble/name quux/mumble/name
  (uniquify-buffer-name-style 'forward))

;;
;; Multiple Windows (info "(emacs) Windows")
;;

(use-package emacs
  :custom
  ;; Resize window by pixel.
  (window-resize-pixelwise t))

(use-package switch-window
  :after (bs-hooks)

  :bind
  ( :map global-map
    ;; When there are more than two windows, select the window to
    ;; switch to by number.
    ([remap other-window] . switch-window)

    ;; When there are re than two windows, select the window to
    ;; maximize to by number.
    ([remap delete-other-windows] . switch-window-then-maximize)

    ;; When there are more than two windows, split the window below by
    ;; selecting its number.
    ([remap split-window-below] . switch-window-then-split-below)

    ;; When there are more than two windows, split the window right by
    ;; selecting its number.
    ([remap split-window-right] . switch-window-then-split-right)))

(use-package winner
  :after (bs-hooks)

  :hook
  ;; Allow undo or redo of windows layout.
  (bs-first-ui-hook . winner-mode))

(use-package winum
  :after (bs-ext)
  :commands (winum-set-keymap-prefix)

  :custom
  ;; Treat window numbering as a per-frame concern, so window-related
  ;; navigation remains local to the current workspace and does not
  ;; leak across independent frames.
  (winum-scope 'frame-local)

  :config
  ;; Keep window-number commands grouped under the same prefix used
  ;; for other window-management actions, preserving a coherent mental
  ;; model for navigating and manipulating windows.
  (winum-set-keymap-prefix (kbd "C-c 4"))

  :hook
  ;; Make window numbering available as part of the normal UI once
  ;; frames are visible, supporting quick window selection during
  ;; interactive work.
  (bs-first-ui-hook . winum-mode))

;;
;; Frames and Graphical Displays (info "(emacs) Frames")
;;

(use-package beframe
  :custom
  ;; Keep a small set of utility buffers shared across all frames, so
  ;; diagnostic and scratch contexts remain accessible regardless of
  ;; frame boundaries.
  (beframe-global-buffers '("*scratch*" "*Messages*" "*Backtrace*"))

  :config
  ;; Bind `beframe' commands to `ctl-c-5-map'.
  (bs-copy-keymap-recursively beframe-prefix-map ctl-c-5-map)

  :hook
  ;; Activate frame-local buffer scoping once the UI is ready, so each
  ;; frame naturally represents an independent working context.
  (bs-first-ui-hook . beframe-mode))

(use-package consult
  :custom
  ;; Favor buffer selection that is scoped to the current context, so
  ;; switching buffers operates on what is relevant to the active
  ;; workspace or project instead of the entire global buffer set.
  (consult-buffer-list-function 'consult--frame-buffer-list)

  :bind
  ( :map global-map
    ;; Press \\`C-x t b' to switch to buffer in another tab.
    ([remap switch-to-buffer-other-tab] . consult-buffer-other-tab)))

(use-package emacs
  :demand t
  :no-require t

  :custom
  ;; Resize frame pixel by pixel.
  (frame-resize-pixelwise t))

(use-package knockknock
  :custom
  ;; Place notification popups at the top center of the frame so they
  ;; stay visible without covering the minibuffer or mode line.
  (knockknock-poshandler 'posframe-poshandler-frame-top-center)

  :hook
  ;; Load the notification backend after early startup work completes,
  ;; when frame geometry and Posframe integration are available.
  (bs-after-startup-early-hook . (lambda () (require 'knockknock))))

(use-package scroll-bar
  :after (bs-hooks)
  :commands (scroll-bar-mode)

  :hook
  ;; Disable the Scroll Bar for all frames once the UI is initialized.
  (bs-first-ui-hook . (lambda () (scroll-bar-mode -1))))

(use-package tab-bar
  :after (bs-hooks)

  :custom
  ;; Only show Tab Bar when have one more tabs.
  (tab-bar-show 1)

  :hook
  ;; Enable `tab-bar-mode'.
  (bs-first-ui-hook . tab-bar-mode))

;;
;; International Character Set Support (info "(emacs) International")
;;

(use-package mule-cmds
  :demand t
  :no-require t
  :commands (set-language-environment prefer-coding-system)
  :functions (set-default-coding-systems)

  :init
  ;; Set the default coding system to UTF-8 for new buffers, files
  ;; and sub-process.
  (set-default-coding-systems 'utf-8)

  ;; Configure the language environment to UTF-8 for system
  ;; messages, input methods, and other locale-sensitive features.
  (set-language-environment "utf-8")

  ;; Prefer UTF-8 when negotiating coding systems for files,
  ;; processes, and inter-program communication.
  (prefer-coding-system 'utf-8))

;;
;; Major and Minor Modes (info "(emacs) Modes")
;;

(use-package files
  :hook
  ;; Guess major mode when saving the buffer.
  (after-save-hook . bs/guess-file-major-mode))

;;
;; Indentation (info "(emacs) Indentation")
;;

(use-package indent
  :demand t
  :no-require t

  :custom
  ;; Always complete first using \\`TAB' key.
  (tab-always-indent 'complete))

(use-package electric
  :config
  ;; Indent after \\`<delete>'.
  (add-to-list 'electric-indent-chars ?\^? t))

(use-package electric
  :after prog-mode
  :hook
  ;; Auto re-indentation when programming.
  (prog-mode-hook . electric-indent-local-mode))

;;
;; Commands for Human Languages (info "(emacs) Text")
;;

(use-package emacs
  :demand t
  :no-require t

  :custom
  ;; Set the global default value of `fill-column' to 70 characters.
  ;; This serves as the baseline for line filling and wrapping
  ;; commands, while allowing major modes or hooks to override it
  ;; buffer-locally as needed.
  (fill-column 70))

(use-package form-feed
  :hook
  ;; Treat form-feed characters as structural landmarks in source
  ;; code, not as legacy control characters to be ignored.
  (after-change-major-mode-hook . form-feed-mode))

(use-package jieba-rs
  :hook
  ;; Enable Jieba-backed word segmentation in text buffers so CJK
  ;; editing commands can move across natural word boundaries.
  (text-mode-hook . jieba-rs-mode))

(use-package paragraphs
  :demand t
  :no-require t

  :custom
  ;; Ensure treat two consecutive spaces after sentence-ending
  ;; punctuation as the canonical sentence boundary.  This affects
  ;; commands such as `forward-sentence', `backward-sentence', and
  ;; filling operations, without modifying the buffer contents or
  ;; inserting extra spaces.
  (sentence-end-double-space t))

(use-package simple
  :after (text-mode)

  :hook
  ;; Enable `auto-fill-mode' in Text Mode buffers.
  (text-mode-hook . auto-fill-mode)

  ;; Set the fill column to 80 characters locally for Text Mode
  ;; buffers.
  (text-mode-hook . (lambda ()
                      (setq-local fill-column 80))))

(use-package simple
  :after (org-mode)

  :hook
  ;; Enable `auto-fill-mode' in Org Mode buffers.
  (org-mode-hook . auto-fill-mode)

  ;; Set the fill column to 80 characters locally for Org Mode
  ;; buffers.
  (org-mode-hook . (lambda ()
                     (setq-local fill-column 80))))

;;
;; Editing Programs (info "(emacs) Programs")
;;

(use-package apheleia
  :after (prog-mode)

  :hook
  ;; Apheleia formats code using external formatter via a non-blocking
  ;; pipeline, typically on save, without interfering with interactive
  ;; editing or modifying buffers outside explicit formatting events.
  (prog-mode-hook . apheleia-mode))

(use-package cape
  :after (prog-mode)
  :commands (cape-dabbrev
             cape-file)

  :hook
  (prog-mode-hook
   .
   (lambda ()
     ;; Make symbols that already exist in the current buffer
     ;; immediately reusable during editing.
     (add-hook 'completion-at-point-functions 'cape-dabbrev 20 t)

     ;; Allow file path completion.
     (add-hook 'completion-at-point-functions 'cape-file -10 t))))

(use-package citre
  :commands (citre-auto-enable-citre-mode)

  :preface
  (defun citre--auto-enable-citre-mode ()
    "Load Citre and try to enable it in programming file buffers."
    (when (derived-mode-p 'prog-mode)
      (require 'citre-config)
      ;; Keep this wrapper as the sole auto-enable entry point; the
      ;; default configuration installs an unfiltered hook itself.
      (remove-hook 'find-file-hook #'citre-auto-enable-citre-mode)
      (citre-auto-enable-citre-mode)))

  :custom
  ;; Enable our citre back-ends.
  (citre-auto-enable-citre-mode-backends '(global tags))

  ;; Let auto enabling citre-mode behavior to work for certain modes.
  (citre-auto-enable-citre-mode-modes '(prog-mode))

  ;; Always use one location to create a tags file.
  (citre-default-create-tags-file-location 'global-cache)

  ;;use ctags options generated by Citre directly, rather than further
  ;; editing them.
  (citre-edit-ctags-options-manually nil)

  :bind
  ( :map ctl-c-c-map
    ;; Jump back to the previous location in the Citre jump stack when
    ;; press \\`C-c c J'.
    ("J" . citre-jump-back)

    ;; Jump to the definition at point using the tags database when
    ;; press \\`C-c c j'..
    ("j" . citre-jump)

    ;; Peek definitions at point using an ace-style selection
    ;; interface when press \\`C-c c p', without leaving the current
    ;; buffer.
    ("p" . citre-ace-peek)

    ;; Update the tags file associated with the current buffer or
    ;; project context when press \\`C-c c u'.
    ("u" . citre-update-this-tags-file))

  :hook
  ;; Load Citre's default configuration and try to enable `citre-mode'
  ;; only when visiting a file whose major mode is configured.
  (find-file-hook . citre--auto-enable-citre-mode))

(use-package consult-eglot-embark
  :after (eglot embark)

  :hook
  ;; Enable `consult-eglot-embark-mode' for buffers managed by Eglot.
  (eglot-managed-mode-hook . consult-eglot-embark-mode))

(use-package consult-imenu
  :bind
  ( :map global-map
    ;; Replace `imenu' with `consult-imenu' to provide better go to
    ;; experience.
    ([remap imenu] . consult-imenu)))

(use-package consult-info
  :bind
  ( :map global-map
    ;; Query a text and search it in the all info manuals, instead
    ;; of opening the index.
    ([remap info] . consult-info)))

(use-package corfu
  :custom
  ;; Enable cycling for `corfu-next' and `corfu-previous'.
  (corfu-cycle t)

  ;; Define behavior when there is an exact match among completion
  ;; candidates.
  (corfu-on-exact-match 'insert)

  ;; Control which candidate is preselected when the completion menu
  ;; appears.
  (corfu-preselect 'prompt)

  ;; Do not preview the currently selected completion candidate in the
  ;; buffer.
  (corfu-preview-current nil)

  ;; Keep the completion menu open when moving across word or symbol
  ;; boundaries, instead of quitting immediately at a boundary.
  (corfu-quit-at-boundary nil)

  ;; Keep the completion menu active even when there is no matching
  ;; candidate, allowing further input without closing the popup.
  (corfu-quit-no-match nil))

(use-package corfu
  :after (prog-mode)

  :hook
  ;; Support incremental code writing by keeping completion available
  ;; as part of the normal editing flow, so identifiers can be refined
  ;; and reused without interrupting typing.
  (prog-mode-hook . corfu-mode))

(use-package corfu-echo
  :after (corfu)
  :commands (corfu-echo-mode)

  :custom
  ;; Display after a shorter delay.
  (corfu-echo-delay 0.5)

  :config
  ;; Display candidate documentation in echo area.
  (corfu-echo-mode +1))

(use-package corfu-history
  :after (corfu)
  :commands (corfu-history-mode)
  :config
  ;; Sort Corfu candidates by history.
  (corfu-history-mode +1))

(use-package corfu-popupinfo
  :after (corfu)
  :commands (corfu-popupinfo-mode)

  :custom
  ;; Display after a short delay to prevent excessive flicker during
  ;; rapid switching and appearing too late.
  (corfu-popupinfo-delay 0.5)

  :config
  ;; Display candidate documentation in child frame.
  (corfu-popupinfo-mode +1))

(use-package eglot
  :after (cape)

  :config
  ;; Allow language-server completions to coexist with other
  ;; completion sources instead of monopolizing the candidate space.
  (advice-add 'eglot-completion-at-point
              :around 'cape-wrap-nonexclusive))

(use-package eglot-booster
  :after (eglot)

  :hook
  ;; Enhance Eglot communication and processing pipeline to reduce
  ;; latency and improve responsiveness, without changing LSP
  ;; semantics or server behavior.
  (eglot-managed-mode-hook . eglot-booster-mode))

(use-package eldoc-box
  :after (eldoc)

  :hook
  ;; Display Eldoc documentation in a child frame near point on hover,
  ;; providing contextual information without using the echo area or
  ;; modifying buffer content.
  (eldoc-mode-hook . eldoc-box-hover-at-point-mode))

(use-package hideshow
  :after (prog-mode)

  :hook
  ;; Allow folding and unfolding of code blocks.
  (prog-mode-hook . hs-minor-mode))

(use-package hl-todo
  :defines (hl-todo-keyword-faces)

  :preface
  (defun hl-todo--set-keyword-faces ()
    "Apply local keyword face overrides when `hl-todo' is loaded."
    (when (featurep 'hl-todo)
      (dolist (entry '(("CNCL" . warning)
                       ("WAIT" . warning)))
        (setf (alist-get (car entry)
                         hl-todo-keyword-faces
                         nil
                         nil
                         #'string=)
              (cdr entry)))))

  :config
  ;; Apply local keyword face overrides when `hl-todo' first loads.
  (hl-todo--set-keyword-faces)

  :hook
  ;; Reapply the overrides after each Modus theme load, but only when
  ;; `hl-todo' has already been used.
  (modus-themes-after-load-theme-hook
   .
   hl-todo--set-keyword-faces)

  ;; Treat TODO markers as active signals during development, not
  ;; passive comments to be rediscovered later.
  (prog-mode-hook . hl-todo-mode))

(use-package nerd-icons-corfu
  :after (corfu)
  :commands (nerd-icons-corfu-formatter)

  :init
  ;; Support faster completion decisions by encoding semantic hints
  ;; visually, so candidate type recognition does not rely solely on
  ;; reading text.
  (add-to-list 'corfu-margin-formatters 'nerd-icons-corfu-formatter))

(use-package newcomment
  :after (prog-mode)

  :hook
  ;; Restrict auto-fill behavior to comments only in programming
  ;; buffers.  When non-nil, `comment-auto-fill-only-comments' ensures
  ;; that automatic line breaking applies exclusively within comment
  ;; syntax, leaving code lines unaffected.
  (prog-mode-hook
   .
   (lambda ()
     (setq-local comment-auto-fill-only-comments t))))

(use-package rainbow-delimiters
  :after (prog-mode)
  :hook
  ;; Colorful parentheses.
  (prog-mode-hook . rainbow-delimiters-mode))

(use-package simple
  :after (prog-mode)

  :hook
  ;; Enable `auto-fill-mode' in Prog Mode buffers.
  (prog-mode-hook . auto-fill-mode))

(use-package smartparens
  :after (prog-mode)

  :hook
  ;; Automatic parentheses operating.
  (prog-mode-hook . smartparens-mode))

(use-package smartparens-config
  :after (smartparens)

  ;; Load `smartparens' config for different major modes.
  :demand t)

(use-package subword
  :after (prog-mode)
  :hook
  ;; Improve cursor movement by treating Camel-case sub-words as
  ;; separate units.
  (prog-mode-hook . subword-mode)

  ;; Treat words separated by punctuation too.
  (prog-mode-hook . superword-mode))

(use-package whitespace
  :hook
  ;; Make invisible formatting issues visible during code writing, so
  ;; unintended whitespace becomes apparent early and can be corrected
  ;; as part of normal editing rather than discovered later.
  (prog-mode-hook . whitespace-mode))

;; C/C++ Programs

(use-package c-ts-mode
  :commands (c-ts-mode c++-ts-mode))

(use-package eglot
  :after (cc-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for classic C/C++
  ;; major modes derived from `cc-mode'.
  ((c-mode-hook c++-mode-hook c-or-c++-mode-hook)
   .
   eglot-ensure))

(use-package eglot
  :after (c-ts-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Tree-sitter
  ;; based C/C++ modes.
  ((c-ts-mode-hook c++-ts-mode-hook)
   .
   eglot-ensure))

(use-package files
  :config
  ;; Replace C Modes with Tree-Sitter based C Modes When a buffer
  ;; would normally activate them.
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode) t)
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode) t))

;; Common Lisp programs

(use-package corfu
  :after (lisp-mode)

  :hook
  ;; Favor incremental construction of Lisp forms by keeping symbol
  ;; completion available during expression-oriented editing.
  (lisp-mode-hook . corfu-mode))

(use-package sly ;; (info "(sly) Top")
  :commands (sly sly-setup)

  :custom
  ;; Default to using SBCL as the Common Lisp implementation.
  (inferior-lisp-program "sbcl")

  :init
  ;; Load SLY contrib packages before run sly.
  (advice-add 'sly :before 'sly-setup)

  :config
  ;; Register our SLY contrib packages want to use.
  (dolist (feature '(sly-asdf
                     sly-macrostep
                     sly-named-readtables
                     sly-stepper))
    (add-to-list 'sly-contribs feature t)))

(use-package sly-completion
  :custom
  ;;
  (sly-symbol-completion-mode nil))

(use-package sly-mrepl
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (sly-mrepl-history-file-name
   (bs-path* bs-state-directory "sly/mrepl-history.el")))

;; Emacs Lisp programs

(use-package paredit
  :after (elisp-mode)
  :hook
  ;; Enable structured editing to enforcing balanced parentheses
  ;; and S-expression integrity by `paredit'.
  (emacs-lisp-mode-hook . paredit-mode))

(use-package pp
  :config
  ;; Add a display buffer rule to make Macroexpand buffers shown in a
  ;; side window at the bottom of the current buffer with its height
  ;; set to 33% of the total buffer height.
  (add-to-list 'display-buffer-alist
               '("\\*Pp Macroexpand Output\\*"
                 (display-buffer-reuse-window
                  display-buffer-below-selected)
                 (window-height . 0.35)))

  :bind
  ( :map ctl-x-map
    ;; Press \\`C-x M-e' to expand macro-expression.
    ("M-e" . pp-macroexpand-last-sexp)))

;; Haskell programs

(use-package eglot
  :after (haskell-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Haskell
  ;; buffers.
  (haskell-mode-hook . eglot-ensure))

(use-package eglot
  :after (haskell-ts-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Tree-sitter
  ;; Haskell buffers.
  (haskell-ts-mode-hook . eglot-ensure))

(use-package files
  :config
  ;; Replace `haskell-mode' with `haskell-ts-mode' When a buffer would
  ;; normally activate `haskell-mode'.
  (add-to-list 'major-mode-remap-alist
               '(haskell-mode . haskell-ts-mode)
               t))

(use-package haskell-mode
  :mode
  ;; Associate haskell files with `haskell-mode'.
  ("\\.l?hs\\'" . haskell-mode))

(use-package haskell-ts-mode
  :commands (haskell-ts-mode))

;; JSON

(use-package eglot
  :after (js-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for JSON buffers.
  (js-json-mode-hook . eglot-ensure))

(use-package eglot
  :after (json-ts-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Tree-sitter
  ;; JSON buffers.
  (json-ts-mode-hook . eglot-ensure))

(use-package files
  :config
  ;; Replace `js-json-mode' with `json-ts-mode' when a buffer would
  ;; normally activate `js-json-mode'.
  (add-to-list 'major-mode-remap-alist
               '(js-json-mode . json-ts-mode)
               t))

(use-package js
  :mode
  ;; Associate JSON-family files with `js-json-mode'.
  ("\\.json\\(?:ld\\)?\\'" . js-json-mode)
  ("\\.\\(?:geo\\|topo\\)json\\'" . js-json-mode)
  ("\\.\\(?:avsc\\|har\\|ipynb\\|sarif\\|webmanifest\\)\\'"
   .
   js-json-mode))

(use-package json-ts-mode
  :commands (json-ts-mode))

;; Nix programs

(use-package eglot
  :after (nix-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Nix buffers.
  (nix-mode-hook . eglot-ensure))

(use-package eglot
  :after (nix-ts-mode)

  :hook
  ;; Automatically start or reuse an Eglot session for Tree-sitter Nix
  ;; buffers.
  (nix-ts-mode-hook . eglot-ensure))

(use-package files
  :config
  ;; Replace `nix-mode' with `nix-ts-mode' When a buffer would
  ;; normally activate `nix-mode'.
  (add-to-list 'major-mode-remap-alist '(nix-mode . nix-ts-mode) t))

(use-package nix-mode
  ;; Associate nix files with `nix-mode'.
  :mode
  ("\\.nix\\'" . nix-mode))

(use-package nix-ts-mode
  :commands (nix-ts-mode))

;; Python programs

(use-package eglot
  :after (python)

  :hook
  ;; Automatically start or reuse an Eglot session for Python buffers.
  (python-mode-hook . eglot-ensure)
  (python-ts-mode-hook . eglot-ensure))

(use-package files
  :config
  ;; Replace `python-mode' with `python-ts-mode' When a buffer would
  ;; normally activate `python-mode'.
  (add-to-list 'major-mode-remap-alist
               '(python-mode . python-ts-mode)
               t))

(use-package python
  :commands (python-ts-mode)

  :mode
  ;; Associate Python source files (including .pyi and .pyw) with
  ;; `python-ts-mode', ensuring Tree-sitter support for all matching
  ;; files.
  ("\\.py[iw]?\\'" . python-mode))

;; Scheme programs

(use-package geiser ;; (info "(geiser) Top")
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (geiser-repl-history-filename (bs-path bs-state-directory
                                         "geiser_history")))

(use-package macrostep-geiser
  :after (geiser-mode)
  :hook
  ;;
  (geiser-mode-hook . macrostep-geiser-setup))

(use-package macrostep-geiser
  :after (geiser-repl)
  :hook
  ;;
  (geiser-repl-mode-hook . macrostep-geiser-setup))

;;
;; Compiling and Testing Programs (info "(emacs) Building")
;;

(use-package consult-flymake
  :after (flymake)

  :bind
  ( :map flymake-mode-map
    ;; Show flymake diagnostic when press \\`C-c !'.
    ("C-c !" . consult-flymake)))

(use-package flymake
  :after (prog-mode)
  :hook
  ;; Enable Flymake.
  (prog-mode-hook . flymake-mode))

(use-package flymake-popon
  :after (flymake)

  :hook
  ;; Enable `flymake-popon-mode' whenever `flymake-mode' is active.
  ;; Diagnostic messages are displayed in a child frame (posframe)
  ;; near point, improving visibility while leaving the echo area
  ;; untouched.  Fallback to `popon' if the graphic is unavailable.
  (flymake-mode-hook . flymake-popon-mode)

  ;; Avoid duplicating diagnostic messages between `flymake-popon' and
  ;; `eldoc-box', since both would otherwise present the same
  ;; information in separate frames.
  (flymake-mode-hook
   .
   (lambda ()
     (remove-hook 'eldoc-documentation-functions
                  'flymake-eldoc-function
                  t))))

(use-package startup
  :demand t
  :no-require t

  :custom
  ;; Clearing the *scratch* buffer.
  initial-scratch-message nil)

;;
;; Maintaining Large Programs (info "(emacs) Maintaining")
;;

(use-package bs-project
  :after (tabspaces)

  :bind
  ;; Allow to switch to a new project tab when find file in the new
  ;; project.
  ([remap project-find-file] . bs-project-find-file))

(use-package consult-project-extra
  :after (consult project)

  :bind
  ( :map ctl-c-p-map
    ;; Find a file in the current project via `consult-project-extra'.
    ("f" . consult-project-extra-find)))

(use-package diff-hl
  :hook
  ;; Enable `diff-hl-mode' when visiting a file.
  (find-file-hook . diff-hl-mode))

(use-package diff-hl
  :after (magit)
  :commands (diff-hl-magit-post-refresh)

  :config
  ;; Synchronize `diff-hl' after Magit's own auto-revert pass, so file
  ;; buffers observe the refreshed Git state.
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh t))

(use-package diff-hl-flydiff
  :hook
  ;; Enable live diff updates while editing.
  (diff-hl-mode-hook . diff-hl-flydiff-mode))

(use-package display-fill-column-indicator
  :after (git-commit)

  :hook
  ;; Treat commit messages as constrained prose that benefits from
  ;; immediate visual guidance, not as free-form text to be fixed
  ;; later.
  (git-commit-mode-hook . display-fill-column-indicator-mode))

(use-package ghostel-dwim
  :after (project)

  :bind
  ( :map global-map
    ;; Use `ghostel' to create shell based on project root.
    ([remap project-shell] . ghostel-dwim-project)

    :map ctl-c-p-map
    ;; Switch to a Ghostel buffer associated with the current project.
    ("C-s" . ghostel-dwim-project-switch)

    ;; Reuse an idle Ghostel session for the current project or create
    ;; one.
    ("s" . ghostel-dwim-project)))

(use-package envrc
  :after (bs-hooks)

  :hook
  ;; Enable `envrc-global-mode' when the first file is visited.  This
  ;; activates direnv-based environment loading for all subsequent
  ;; buffers, ensuring that project-local environment variables are
  ;; applied automatically without affecting startup performance.
  (bs-first-file-hook . envrc-global-mode))

(use-package git-commit
  :custom
  ;; Enforce a concise commit subject line to encourage clear,
  ;; scannable commit history and improve readability in tools that
  ;; display summaries in constrained layouts.
  (git-commit-summary-max-length 68)

  :hook
  ;; Use a wider text column for commit message bodies to support
  ;; well-structured explanations while keeping the subject line
  ;; visually and semantically distinct.
  (git-commit-mode-hook . (lambda ()
                            (setq-local fill-column 72))))

(use-package magit
  :after (bs-ext)
  :commands (magit-init
             magit-status-setup-buffer)

  :custom
  ;; Disable Magit's global key bindings.
  (magit-define-global-key-bindings nil)

  :bind
  ( :map ctl-c-v-map
    ;; Press \\`C-c v g' to display Magit.
    ("g" . magit)))

(use-package magit-autorevert
  :after (magit)
  :commands (magit-auto-revert-mode)

  :init
  ;; Enable repository-aware auto-revert only after Magit is first
  ;; loaded, keeping the integration out of the startup path.
  (magit-auto-revert-mode +1))

(use-package magit-status
  :after (magit)

  :config
  ;; Show Magit Status in the shared bottom side window used for
  ;; commit message editing.
  (add-to-list 'display-buffer-alist
               '((derived-mode . magit-status-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0))))

(use-package project
  :after (bs-lib)

  :custom
  ;; Persist projects list.
  (project-list-file (bs-path bs-state-directory "projects.el")))

(use-package tabspaces
  :custom
  ;; Keep a small set of global utility buffers visible across all
  ;; workspaces, while preventing project-specific or navigation
  ;; buffers from leaking between tabs.
  (tabspaces-exclude-buffers '())

  ;; Treat workspaces as isolated contexts by default, rather than
  ;; sharing buffers implicitly across tabs.
  (tabspaces-include-buffers '("*Backtrace*"
                               "*Messages*"
                               "*scratch*"))

  ;; Avoid introducing opinionated project artifacts, keeping project
  ;; structure under explicit user control.
  (tabspaces-initialize-project-with-todo nil)

  ;; Disable default key bindings so workspace control can be
  ;; integrated into an existing, coherent key name-space.
  (tabspaces-keymap-prefix nil)

  ;; Persist workspace state across sessions to preserve long-running
  ;; context, without forcing automatic restoration on startup.
  (tabspaces-session t)
  (tabspaces-session-file (bs-path* bs-state-directory
                                    "tabspaces/sessions.el"))
  (tabspaces-session-project-session-store
   (bs-path* bs-state-directory "tabspaces/"))

  ;; Require explicit intent to restore sessions, preventing stale
  ;; workspaces from being resurrected unintentionally.
  (tabspaces-session-auto-restore nil)

  ;; Keep buffer selection unified under a single interface instead of
  ;; fragmenting navigation between competing buffer lists.
  (tabspaces-use-filtered-buffers-as-default nil)

  :bind
  ( :map global-map
    ;; Use `tabspaces' to open or switch project by default.
    ([remap project-switch-project]
     .
     tabspaces-open-or-create-project-and-workspace)

    :map ctl-c-t-map
    ;; Press \\`C-c t C' to clear all buffers in the current
    ;; workspace, keeping the tab structure while resetting its
    ;; working state.
    ("C" . tabspaces-clear-buffers)

    ;; Press \\`C-c t R' to remove a selected buffer from the current
    ;; workspace without affecting other tabs or projects.
    ("R" . tabspaces-remove-selected-buffer)

    ;; Press \\`C-c t S' to switch both buffer and workspace in one
    ;; step, allowing navigation to follow context rather than
    ;; requiring separate tab and buffer operations.
    ("S" . tabspaces-switch-buffer-and-tab)

    ;; Press \\`C-c t b' to create a new workspace or switch to an
    ;; existing one, treating workspaces as the primary unit of task
    ;; separation.
    ("b" . tabspaces-switch-or-create-workspace)

    ;; Press \\`C-c t d' to close the current workspace while leaving
    ;; other workspaces intact.
    ("d" . tabspaces-close-workspace)

    ;; Press \\`C-c t k' to tear down a workspace completely by
    ;; killing its buffers and closing the tab, signaling that the
    ;; task context is finished.
    ("k" . tabspaces-kill-buffers-close-workspace)

    ;; Press \\`C-c t o' to open a project and establish a
    ;; corresponding workspace in one action, aligning project
    ;; boundaries with workspace boundaries.
    ("o" . tabspaces-open-or-create-project-and-workspace)

    ;; Press \\`C-c t r' to remove the current buffer from the
    ;; workspace without killing it, allowing it to be reused in other
    ;; contexts.
    ("r" . tabspaces-remove-current-buffer)

    ;; Press \\`C-c t s' to switch buffers within the current
    ;; workspace, keeping navigation scoped to the active context.
    ("s" . tabspaces-switch-to-buffer))

  :hook
  ;; Activate workspace semantics whenever tab-bar mode is in use, so
  ;; tabs consistently represent isolated work contexts rather than
  ;; merely visual groupings.
  (tab-bar-mode-hook . tabspaces-mode))

(use-package treemacs-async
  :after (treemacs)
  :commands (treemacs-git-mode)

  :init
  ;; Allow Git state updates to be applied asynchronously, so visual
  ;; corrections from version-control actions do not block tree
  ;; navigation.
  (treemacs-git-mode 'deferred))

(use-package treemacs-magit
  :after (magit treemacs)

  ;; Load the bridge only when both applications are in use, so
  ;; opening either one alone does not pull in the other.
  :demand t)

(use-package treemacs-git-commit-diff-mode
  :after (treemacs)
  :commands (treemacs-git-commit-diff-mode)

  :init
  ;; Make commit diffs visible in relation to the project tree, so
  ;; changes introduced by a commit can be understood in their
  ;; directory context rather than as an isolated list of files.
  (treemacs-git-commit-diff-mode +1))

(use-package treemacs-project-follow-mode
  :after (treemacs)
  :commands (treemacs-project-follow-mode)

  :init
  ;; Keep the active Treemacs project aligned with the project of the
  ;; current buffer, so navigation always reflects the context being
  ;; worked on rather than a previously selected tree.
  (treemacs-project-follow-mode +1))

(use-package whitespace
  :after (magit-diff)

  :hook
  ;; Make whitespace-only changes visible when reviewing diffs, so
  ;; formatting modifications are evaluated explicitly instead of
  ;; being overlooked among substantive code changes.
  (magit-diff-mode-hook . whitespace-mode))

;;
;; Abbrevs (info "(emacs) Abbrevs")
;;

;;
;; Dired, the Directory Editor (info "(emacs) Dired")
;;

(use-package dired
  :custom
  ;; Favor workflows that treat file operations as transfers between
  ;; visible locations, reducing the need to manually specify targets
  ;; when working across multiple Dired buffers.
  (dired-dwim-target t)

  ;; Optimize for batch-oriented file management by removing
  ;; confirmation friction when operating on directory trees.
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)

  ;; Present directory listings in a way that supports quick
  ;; structural understanding: focus on meaningful files, readable
  ;; sizes, and a stable ordering that keeps directories prominent.
  (dired-listing-switches (string-join '("-l"
                                         "--almost-all"
                                         "--human-readable"
                                         "--group-directories-first"
                                         "--no-group")
                                       " ")))

(use-package dired
  :after (display-fill-column-indicator)

  :hook
  (dired-mode-hook
   .
   (lambda ()
     ;; Keep directory listings visually unconstrained by text-column
     ;; guides, so file names and metadata can be scanned as a
     ;; continuous table rather than as wrapped prose.
     (when (bound-and-true-p display-fill-column-indicator-mode)
       (display-fill-column-indicator-mode -1)))))

(use-package dired-x
  :after (dired)

  :custom
  ;; Keep omission behavior quiet and unobtrusive, so directory views
  ;; stay focused on relevant entries without drawing attention to
  ;; what has been filtered out.
  (dired-omit-verbose nil)

  :hook
  ;; Reduce visual noise in directory listings by hiding routinely
  ;; uninteresting files, allowing attention to stay on files that are
  ;; actively worked with.
  (dired-mode-hook . dired-omit-mode))

(use-package diredfl
  :after (dired)

  :hook
  ;; Emphasize structural differences in directory listings through
  ;; visual distinction, making it easier to separate files,
  ;; directories, and states at a glance during navigation and batch
  ;; operations.
  (dired-mode-hook . diredfl-mode))

(use-package nerd-icons-dired
  :after (dired)

  :hook
  ;; Support faster visual parsing of directory listings by using
  ;; icons as pre-attentive cues, helping identify file types and
  ;; roles without reading full filenames.
  (dired-mode-hook . nerd-icons-dired-mode))

;;
;; The Calendar and the Diary (info "(emacs) Calendar/Diary")
;;

(use-package calfw-org
  :after (org)
  :commands (calfw-org-open-calendar)

  :bind
  ( :map ctl-c-a-map
    ;; Open a calendar view backed by the same Org files used by the
    ;; agenda.  Press \\`v w' or \\`v m' there to switch between week
    ;; and month views.
    ("k" . calfw-org-open-calendar)))

(use-package bs-khal
  :after (bs-ext)
  :commands (bs-khal-capture
             bs-khal-import-events
             bs-khal-setup)

  :custom
  ;; Check the calendar sources every five minutes, importing only
  ;; when their persisted state differs from the last successful run.
  (bs-khal-import-check-interval 300))

(use-package khalel
  :defines (khalel-capture-key)

  :custom
  ;; Use \\`c' for calendar events in the Org capture menu.
  (khalel-capture-key "c")

  ;; Include events up to ninety days in the future in the generated
  ;; Org calendar mirror.
  (khalel-import-end-date "+90d")

  ;; Let `bs-khal' refresh the mirror asynchronously after exporting a
  ;; captured event.
  (khalel-import-events-after-capture nil)

  ;; Let `bs-khal' refresh the mirror asynchronously after khal edit
  ;; exits successfully.
  (khalel-import-events-after-khal-edit nil)

  ;; Let `bs-khal' refresh the mirror asynchronously after a
  ;; vdirsyncer process exits successfully.
  (khalel-import-events-after-vdirsyncer nil)

  ;; Store the generated calendar mirror alongside the other Org data.
  (khalel-import-org-file
   (bs-path* org-directory "calendar.org"))

  ;; Replace the generated mirror without prompting, since it contains
  ;; imported data rather than user-authored entries.
  (khalel-import-org-file-confirm-overwrite nil)

  ;; Protect imported entries from accidental edits; changes should be
  ;; made through Khalel or the source calendar.
  (khalel-import-org-file-read-only t)

  ;; Include the previous seven days so recent events remain available
  ;; in agenda and calendar views.
  (khalel-import-start-date "-7d")

  ;; Keep remote synchronization independent from event capture.
  (khalel-run-vdirsyncer-after-capture nil))

;;
;; Sending Mail (info "(emacs) Sending Mail")
;;

(use-package mml-sec
  :after (message)

  :config
  ;; Show MML signing option prompts in a dedicated bottom side
  ;; window, keeping the message buffer visible while choosing signing
  ;; settings.
  (add-to-list 'display-buffer-alist
               '("\\*MML sender signing options\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . fit-window-to-buffer)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))))

  :hook
  ;; Sign new outgoing messages with PGP/MIME by default.
  (message-setup-hook . mml-secure-message-sign-pgpmime))

;;
;; Reading Mail with Rmail (info "(emacs) Rmail")
;;

;;
;; Email and Usenet News with Gnus (info "(emacs) Gnus")
;;

;;
;; Host Security (info "(emacs) Host Security")
;;

(use-package files
  :config
  ;; Extend the 'trusted-content' option by appending the user's home
  ;; directory.
  (add-to-list 'trusted-content "~/" t))

;;
;; Network Security (info "(emacs) Network Security")
;;

;;
;; Document Viewing (info "(emacs) Document View")
;;

;;
;; Running Shell Commands from Emacs (info "(emacs) Shell")
;;

(use-package comint
  :after (cape)

  :config
  ;; Favor iterative exploration at REPL prompts by keeping completion
  ;; open to past input and local context, rather than forcing a
  ;; single, authoritative completion source.
  (advice-add 'comint-completion-at-point
              :around 'cape-wrap-nonexclusive))

(use-package corfu
  :after (comint)

  :hook
  ;; Treat completion as part of interactive exploration rather than a
  ;; separate lookup step in command-driven buffers.
  (comint-mode-hook . corfu-mode))

(use-package ghostel
  :config
  ;; Add a display buffer rule to make Ghostel buffers shown in a side
  ;; window at the bottom of the frame.
  (add-to-list 'display-buffer-alist
               '((derived-mode . ghostel-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.35)))

  :hook
  ;; Export environment variables so that programs launched from
  ;; Ghostel use Emacs as their editor.
  (ghostel-pre-spawn-hook
   .
   (lambda ()
     ;; Compute EMACS_SERVER_FILE in a reproducible way.  server-name
     ;; defaults to server; server-socket-dir is auto-chosen by Emacs.
     (let* ((server-file (expand-file-name server-name
                                           server-socket-dir))
            ;; Choose how external tools should invoke Emacs.
            ;; -c/--create-frame opens a GUI frame when possible.
            ;; --alternate-editor=\"\" prevents starting a separate
            ;; editor fallback.
            (editor (mapconcat #'identity
                               '("emacsclient"
                                 "--alternate-editor=\"\""
                                 "--create-frame")
                               " ")))
       (setenv "EDITOR" editor)
       (setenv "EMACS_SERVER_FILE" server-file)))))

(use-package ghostel-dwim
  :bind
  ( :map ctl-c-a-map
    ;; Switch to a Ghostel buffer associated with the current
    ;; directory.
    ("C-s" . ghostel-dwim-switch)

    ;; Reuse an idle Ghostel session for the current directory or
    ;; create one.
    ("s" . ghostel-dwim)))

(use-package shell-maker
  :custom
  ;; Keep shell-maker state beneath the shared Emacs state directory
  ;; instead of scattering generated files into project trees.
  (shell-maker-root-path (bs-path* bs-state-directory)))

(use-package with-editor
  :bind
  ( :map global-map
    ;; Remap shell command entry points to `with-editor' variants.
    ([remap async-shell-command] . with-editor-async-shell-command)
    ([remap shell-command] . with-editor-shell-command)))

(use-package with-editor
  :after (esh-mode)

  :hook
  ;; Export $EDITOR/$VISUAL for Eshell sessions.
  (eshell-mode-hook . with-editor-export-editor))

(use-package with-editor
  :after (shell)

  :hook
  ;; Export $EDITOR/$VISUAL for `shell-mode' buffers.
  (shell-mode-hook . with-editor-export-editor))

(use-package with-editor
  :after (term)

  :hook
  ;; Export $EDITOR/$VISUAL for `term-mode' sessions.
  (term-mode-hook . with-editor-export-editor))

;;
;; Using Emacs as a Server (info "(emacs) Emacs Server")
;;

(use-package bs-lib
  :after (bs-hooks)

  :hook
  ;; Start the Emacs server after early startup initialization has
  ;; completed.  This ensures that the server is launched only once
  ;; the core startup hooks have run, providing a stable environment
  ;; for subsequent emacsclient connections.
  (bs-after-startup-early-hook . bs/server-start))

;;
;; Printing Hard Copies (info "(emacs) Printing")
;;

;;
;; Sorting Text (info "(emacs) Sorting")
;;

;;
;; Editing Pictures (info "(emacs) Picture Mode")
;;

;;
;; Editing Binary Files (info "(emacs) Editing Binary Files")
;;

;;
;; Saving Emacs Sessions (info "(emacs) Saving Emacs Sessions")
;;

(use-package saveplace
  :after (:all bs-hooks bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (save-place-file (bs-path bs-state-directory "place.el"))

  :hook
  ;; Persist and restore cursor positions across sessions.
  (bs-first-file-hook . save-place-mode))

(use-package startup
  :demand t
  :no-require t
  :after (bs-lib)

  :custom
  ;; Emacs maintains auto-save-list files to track existing auto-save
  ;; backups for crash recovery.  By default these lists live under
  ;; `user-emacs-directory', but to keep session state centralized and
  ;; avoid cluttering `user-emacs-directory' directory, we point
  ;; `auto-save-list-file-prefix' at our data directory’s
  ;; auto-save-list folder with the prefix saves-, so all recovery
  ;; metadata is stored alongside other state files.
  (auto-save-list-file-prefix (concat (bs-path* bs-state-directory
                                                "auto-save-list/")
                                      "saves-")))

;;
;; Recursive Editing Levels (info "(emacs) Recursive Edit")
;;

;;
;; Hyperlinking and Web Navigation Features
;; (info "(emacs) Hyperlinking")
;;

;;
;; Games and Other Amusements (info "(emacs) Amusements")
;;

;;
;; Emacs Lisp Packages (info "(emacs) Packages")
;;

;;
;; Customization (info "(emacs) Customization")
;;

(use-package auth-source
  :custom
  ;; Centralize all credential lookup to a single, explicitly managed
  ;; secrets file, keeping authentication material under direct
  ;; control rather than scattered across implicit sources.
  (auth-sources `(,(bs-path bs-config-directory "authinfo.gpg"))))

(use-package auth-source-pass
  :after (auth-source)
  :commands (auth-source-pass-enable)

  :init
  ;; Treat the password store as the authoritative source for secrets,
  ;; so credentials are encrypted at rest and shared consistently
  ;; across tools that rely on `auth-source`.
  (auth-source-pass-enable))

(use-package cus-edit
  :after (bs-lib)

  :custom
  ;; To keep state and avoid cluttering our init file with
  ;; auto-generated settings, let Emacs writes `custom-set-variables'
  ;; and `custom-set-faces' to our state directory instead of tacking
  ;; them onto our init file.
  (custom-file (bs-path bs-state-directory "custom.el"))

  :hook
  ;; Load custom values set before init, and properly restore the
  ;; environment.  Because it may include faces, we choose to load it
  ;; in `emacs-startup-hook'.
  (emacs-startup-hook . (lambda ()
                          (load custom-file 'noerror 'nomessage))))

(use-package pass
  :commands (pass)

  :custom
  ;; Allow usernames to be inferred from entry names when no explicit
  ;; username is stored, reducing duplication and keeping the password
  ;; store concise.
  (pass-username-fallback-on-filename t)

  :config
  ;; Present the password store interface as a contextual, temporary
  ;; workspace below the current buffer, so secret lookup does not
  ;; disrupt the main editing context.
  (add-to-list 'display-buffer-alist
               '("\\*Password-Store\\*"
                 (display-buffer-reuse-window
                  display-buffer-below-selected)
                 (window-height . 0.35))))

;;
;; Quitting and Aborting (info "(emacs) Quitting")
;;

;;
;; Contributing to Emacs Development (info "(emacs) Contributing")
;;

(use-package copyright
  :custom
  ;; Ensure file headers include correct copyright information.
  copyright-names-regexp
  (format "%s <%s>" user-full-name user-mail-address))


;;
;; Agents
;;

(use-package agent-recall
  :custom
  ;; Show recently changed conversations first when browsing recalled
  ;; agent sessions.
  (agent-recall-browse-sort 'modified-desc)

  ;; Use `consult-ripgrep' interface for full-text recall searches.
  (agent-recall-search-function 'consult-ripgrep)

  ;; Limit recall indexing and search to source checkouts.
  (agent-recall-search-paths '("~/src")))

(use-package agent-review
  :bind
  ( :map ctl-c-x-map
    ;; Start an agent-assisted review from the custom agent prefix
    ;; map.
    ("r" . agent-review)))

(use-package agent-shell
  :custom
  ;; Default new agent shells to the Codex OpenAI agent configuration.
  (agent-shell-preferred-agent-config
   (agent-shell-openai-make-codex-config))

  ;; Open agent shells directly at the prompt without the package
  ;; welcome text.
  (agent-shell-show-welcome-message nil)

  :config
  ;; Store agent-shell cache entries under `bs-cache-directory' while
  ;; preserving the package helper's component-based path interface.
  (advice-add 'agent-shell--cache-dir
              :override
              #'(lambda (&rest components)
                  (let* ((base-dir
                          (bs-path bs-cache-directory "agent-shell/"))
                         (cache-dir
                          (apply #'bs-path base-dir components)))
                    (make-directory cache-dir t)
                    cache-dir))

              '((name . agent-shell--cache-dir-redirect)))

  :bind
  ( :map agent-shell-mode-map
    ;; Interrupt the running agent process from inside its shell
    ;; buffer.
    ("C-c C-k" . agent-shell-interrupt)))

(use-package agent-shell-knockknock
  :after (agent-shell knockknock)

  :hook
  ;; Enable desktop notifications for each interactive agent shell.
  (agent-shell-mode-hook . agent-shell-knockknock-mode))

(use-package agent-shell-manager
  :custom
  ;; Let `display-buffer-alist' choose the regular window placement,
  ;; matching list buffers such as `ibuffer' instead of forcing a side
  ;; window.
  (agent-shell-manager-side nil)

  :config
  ;; Show the manager in the selected window like `ibuffer'.  The
  ;; package displays the buffer before enabling
  ;; `agent-shell-manager-mode', so match the buffer name rather than
  ;; the major mode.
  (add-to-list 'display-buffer-alist
               '("\\*Agent-Shell Buffers\\*"
                 (display-buffer-same-window)))

  ;; `agent-shell-manager-toggle' dedicates the displayed window.
  ;; That is appropriate for side windows, but regular same-window
  ;; display should remain reusable like `ibuffer'.
  (advice-add 'agent-shell-manager-toggle
              :around
              #'(lambda (orig &rest args)
                  (let* ((buffer
                          (get-buffer "*Agent-Shell Buffers*"))
                         (window
                          (and buffer
                               (get-buffer-window buffer))))
                    (if (and (null agent-shell-manager-side)
                             (window-live-p window))
                        (progn
                          (set-window-dedicated-p window nil)
                          (quit-window nil window))
                      (prog1 (apply orig args)
                        (when-let*
                            ((buffer
                              (get-buffer "*Agent-Shell Buffers*"))
                             (window
                              (get-buffer-window buffer)))
                          (when (null agent-shell-manager-side)
                            (set-window-dedicated-p window nil)))))))
              '((name . agent-shell-manager-buffer-normalize)))

  :bind
  ( :map ctl-c-x-map
    ;; Toggle the agent-shell manager from the custom agent prefix
    ;; map.
    ("C-b" . agent-shell-manager-toggle)))

(use-package agent-shell-sidebar
  :custom
  ;; Use the Codex OpenAI agent configuration for sidebar sessions.
  (agent-shell-sidebar-default-config
   (agent-shell-openai-make-codex-config))

  :bind
  ( :map ctl-c-x-map
    ;; Toggle the persistent agent sidebar from the custom agent
    ;; prefix map.
    ("s" . agent-shell-sidebar-toggle)))

(use-package agent-shell-tramp
  :after (agent-shell)
  :commands (agent-shell-tramp-mode)

  :config
  ;; Enable TRAMP integration so agent shells can operate on remote
  ;; buffers and paths.
  (agent-shell-tramp-mode +1))

(use-package codex-ide
  :custom
  ;; Sit and relax, patiently waiting for the app-server thread to be
  ;; ready.
  (codex-ide-request-timeout 60)

  :config
  ;; Display Codex session buffers in a persistent right side window,
  ;; keeping conversations visible without replacing the current
  ;; editing window.
  (add-to-list 'display-buffer-alist
               '((derived-mode . codex-ide-session-mode)
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (dedicated . t)
                 (preserve-size . (t . nil))
                 (side . right)
                 (slot . 0)
                 (window-parameters . ((no-delete-other-windows . t)))
                 (window-width . 0.5)))

  :bind
  ( :map ctl-c-x-map
    ;; Start Codex IDE from the custom agent prefix map.
    ("c" . codex-ide)

    ;; Open the Codex IDE menu from the custom agent prefix map.
    ("C-c" . codex-ide-menu)))

(use-package codex-ide-session-mode
  :bind
  ( :map codex-ide-session-mode-map
    ;; Submit Codex prompts with the same key used by shell-maker
    ;; buffers.
    ("C-c C-c" . codex-ide-submit)

    ;; Leave \\`C-c RET' unbound so prompt submission has a single
    ;; mnemonic binding in Codex sessions.
    ("C-c RET" . nil)))

(use-package corfu
  :after (codex-ide-session-mode)

  :hook
  ;; Enable Corfu in Codex sessions so automatic slash command
  ;; completion uses the popup frontend instead of `*Completions*'.
  (codex-ide-session-mode-hook . corfu-mode))

(use-package mcp-server
  :custom
  ;; Keep MCP server sockets under the Emacs state directory so
  ;; runtime files do not live in the source tree.
  (mcp-server-socket-directory (bs-path bs-state-directory "mcp/"))

  :hook
  ;; Start the Unix socket MCP server after late startup, making the
  ;; running Emacs session available to agent clients without adding
  ;; work to the initial startup path.
  (bs-after-startup-late-hook . mcp-server-start-unix))

(use-package openspec
  :custom
  ;; Disable OpenSpec's default global binding; expose the status
  ;; command under the custom agent prefix map instead.
  (openspec-status-key nil)

  :config
  ;; Show OpenSpec status buffers in a bottom side window so reviewing
  ;; proposals and tasks does not replace the current editing window.
  (add-to-list 'display-buffer-alist
               '((derived-mode . openspec-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)))

  :bind
  ( :map ctl-c-x-map
    ;; Open the OpenSpec project status from the custom agent prefix
    ;; map.
    ("o" . openspec-status)))

(use-package shell-maker
  :after (agent-shell)

  :bind
  ( :map agent-shell-mode-map
    ;; Submit the current shell-maker input without leaving insert
    ;; flow.
    ("C-c C-c" . shell-maker-submit)))

(use-package simple
  :after (agent-shell)

  :bind
  ( :map agent-shell-mode-map
    ;; Keep RET as a plain newline inside agent-shell buffers;
    ;; explicit submission remains on \\`C-c C-c'.
    ("RET" . newline)))

;;
;; Denote (info "(denote) Top")
;;

(use-package consult-denote
  :after (bs-hooks)

  :bind
  ( :map ctl-c-n-map
    ;; Search and select Denote notes using `consult', providing
    ;; narrowing, preview, and live filtering over note filenames.
    ("f" . consult-denote-find)

    ;; Perform full-text search across Denote notes using `consult' as
    ;; the front-end, enabling interactive narrowing of grep results.
    ("g" . consult-denote-grep))

  :hook
  ;; Enable `consult-denote-mode' early after startup.  This activates
  ;; integration between Consult and Denote, ensuring that
  ;; Consult-based commands are aware of Denote notes without
  ;; requiring manual activation per buffer.
  (bs-after-startup-late-hook . consult-denote-mode))

(use-package denote
  :after (bs-lib)
  :commands (denote-rename-buffer-mode)

  :custom
  ;; Use Org date reader when prompting for dates, enabling calendar
  ;; navigation and flexible date input.
  (denote-date-prompt-use-org-read-date t)

  ;; Set the root directory for Denote notes.  All notes are stored
  ;; beneath this path.
  (denote-directory (bs-path* "~/org" "notes"))

  ;; Do not exclude any subdirectories under `denote-directory'.
  (denote-excluded-directories-regexp nil)

  ;; Infer keywords automatically from note content and context
  ;; when creating or renaming notes.
  (denote-infer-keywords t)

  ;; Do not exclude any keywords from the inference process.
  (denote-keywords-to-not-infer-regexp nil)

  ;; Define the set of known keywords used for completion and
  ;; validation.
  (denote-known-keywords '("emacs"))

  ;; Prompt only for title and keywords when creating new notes.
  (denote-prompts '(title keywords))

  ;; Request confirmation when rewriting front matter or modifying
  ;; file names during rename operations.
  (denote-rename-confirmations
   '(rewrite-front-matter modify-file-name))

  ;; Do not automatically save buffers during Denote operations.
  (denote-save-buffers nil)

  ;; Sort keywords alphabetically when writing them to front
  ;; matter.
  (denote-sort-keywords t)

  :config
  ;; Enable automatic buffer renaming to keep buffer names in sync
  ;; with Denote file names.
  (denote-rename-buffer-mode +1)

  :bind
  ( :map ctl-c-n-map
    ;; Insert links to existing Denote notes, with interactive
    ;; selection and completion.
    ("L" . denote-add-links)

    ;; Rename the current note using its front matter as the source
    ;; of truth for title and keywords.
    ("R" . denote-rename-file-using-front-matter)

    ;; Display back-links for the current note, showing which notes
    ;; reference it.
    ("b" . denote-backlinks)

    ;; Open a Dired buffer rooted at the Denote notes directory.
    ("d" . denote-dired)

    ;; Insert a link to another Denote note.
    ("l" . denote-link)

    ;; Create a new Denote note.
    ("n" . denote)

    ;; Insert a link generated from a content-based Denote query.
    ("q c" . denote-query-contents-link)

    ;; Insert a link generated from a filename-based Denote query.
    ("q f" . denote-query-filenames-link)

    ;; Rename the current Denote file interactively.
    ("r" . denote-rename-file)))

(use-package denote
  :after (dired)

  :custom
  ;; Define the controlled vocabulary offered during keyword
  ;; completion, combining note roles with the `emacs' topic.
  (denote-known-keywords '("decision"
                           "emacs"
                           "journal"
                           "meeting"
                           "person"
                           "project"
                           "reference"))

  :bind
  ( :map dired-mode-map
    ;;  Rename marked Denote files using their front matter.
    ("C-c C-d C-R"
     .
     denote-dired-rename-marked-files-using-front-matter)

    ;; Insert links to all marked Denote notes.
    ("C-c C-d C-i" . denote-dired-link-marked-notes)

    ;; Rename marked Denote files by modifying their keyword sets.
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)

    ;; Rename marked Denote files interactively.
    ("C-c C-d C-r" . denote-dired-rename-files))

  :hook
  ;; Enable `denote-dired-mode' in Dired buffers.  This augments Dired
  ;; with Denote-specific commands and metadata handling.
  (dired-mode-hook . denote-dired-mode))

(use-package denote-journal
  :after (denote)

  :custom
  ;; Reuse one journal entry per calendar day instead of creating a
  ;; separate entry on every invocation.
  (denote-journal-interval 'daily)

  ;; Mark every journal entry with `journal' so it can be identified
  ;; and retrieved independently of ordinary Denote notes.
  (denote-journal-keyword "journal")

  :bind
  ( :map ctl-c-n-map
    ;; Visit today's journal entry or create it when absent; a prefix
    ;; argument selects another date.
    ("j" . denote-journal-new-or-existing-entry)))

;;
;; EasyPG Assistant (info "(epa) Top")
;;

(use-package epa-file
  :custom
  ;; Set the default recipient(s) for file encryption.  When saving an
  ;; encrypted file without specifying recipients explicitly,
  ;; `user-mail-address' key will be used by default.
  (epa-file-encrypt-to `(,user-mail-address))

  ;; Set the default recipient(s) for file encryption.  When saving an
  ;; encrypted file without specifying recipients explicitly, these
  ;; keys will be used by default.
  (epa-file-select-keys 'silent))

(use-package epa-file
  :after (epa)
  :commands (epa-file-enable)

  :config
  ;; Silencing all messages during `epa-file-enable' executing.
  (advice-add 'epa-file-enable :around 'bs-silence-message)

  ;; Enable epa-file so that Emacs can automatically recognize and
  ;; transparently handle *.gpg files.  When opening an encrypted
  ;; file, it is automatically decrypted; when saving, it is
  ;; automatically encrypted again.
  (epa-file-enable))

(use-package epg-config
  :custom
  ;; Configure EasyPG to use loop-back pinentry mode, so that Emacs
  ;; handles passphrase prompts internally instead of spawning an
  ;; external pinentry program.  This allows password input directly
  ;; in the mini-buffer.
  (epg-pinentry-mode 'loopback))

;;
;; Contacts
;;

(use-package bs-contacts
  :commands (bs-contacts-create
             bs-contacts-delete
             bs-contacts-edit
             bs-contacts-edit-cancel
             bs-contacts-edit-submit
             bs-contacts-refresh
             bs-contacts-select
             bs-contacts-show
             bs-contacts-sync)

  :defer t)

;;
;; mu4e
;;

(use-package bs-mu4e
  :after (mu4e-compose)
  :commands (bs-mu4e-compose-completion-enable)
  :defines (bs-mu4e-ignored-contact-display-name-regexp)

  :custom
  ;; Ignore account-specific automated and non-person addresses.
  (bs-mu4e-ignored-contact-email-regexps
   '(;; Amazon SES envelope sender addresses.
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*amazonses\\.com\\'"

     ;; Atlassian bounce domains whose pre-organization label
     ;; contains "bounces".
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*[^@.]*bounces[^@.]*\\.atlassian\\.[^@]+\\'"

     ;; Stripe's dedicated bounce domain.
     "\\`[^@]+@bounce\\.stripe\\.com\\'"

     ;; Linux Foundation encoded-recipient envelope addresses.
     "\\`[[:alnum:]]+-[^@=]+=.+@\\(?:[^@.]+\\.\\)+linuxfoundation\\.org\\'"

     ;; Mailing-list rewritten senders, preserving normal list
     ;; posting addresses without an equals sign.
     "\\`[^@=]+=.+@lists\\.[^@]+\\'"

     ;; KDE Invent generated incoming addresses.
     "\\`incoming\\+[^@]+@invent\\.kde\\.org\\'"

     ;; SurveyMonkey outbound platform addresses.
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*outbound\\.surveymonkey\\.com\\'"

     ;; Substack platform addresses.
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*substack\\.com\\'"

     ;; SparkPost delivery platform addresses.
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*sparkpost\\.com\\'"

     ;; DingTalk generated forwarding addresses.
     "\\`fw[[:digit:]]+-[[:alnum:]]+@dingtalk\\.com\\'"

     ;; Cloudflare transactional addresses.
     "\\`em@em[[:digit:]]+\\.cloudflare\\.com\\'"

     ;; Mailing-list notice bounce addresses.
     "\\`noticebounce\\(?:\\+[^@]+\\)?@[^@]+\\'"

     ;; Automated notice addresses.
     "\\`\\(?:notice\\|[^@+]+[._-]notice\\)\\(?:\\+[^@]+\\)?@[^@]+\\'"

     ;; Automated verification addresses.
     "\\`[^@+]*verification\\(?:\\+[^@]+\\)?@[^@]+\\'"

     ;; Automated return addresses.
     "\\`return-to\\(?:\\+[^@]+\\)?@[^@]+\\'"

     ;; Generic role addresses that do not identify a person.
     "\\`automation\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`bulletin\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`confluence\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`email\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`events\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`hello\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`help\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`info\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`invoice\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`mailer\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`marketing\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`meetings\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`membership\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`payments\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`receipts\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`reports\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`service\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`shop\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`support\\(?:\\+[^@]+\\)?@[^@]+\\'"
     "\\`webmaster\\(?:\\+[^@]+\\)?@[^@]+\\'"

     ;; Account-specific organization addresses.
     "\\`nscc-cas@cnic\\.cn\\'"
     "\\`cstcloud@cnic\\.cn\\'"
     "\\`dccloud@cnic\\.cn\\'"
     "\\`it_fapiao@meituan\\.com\\'"
     "\\`12306@rails\\.com\\.cn\\'"))

  :init
  ;; Normalize mu4e's compose completion candidates so display names
  ;; stay readable and automated senders are hidden.
  (bs-mu4e-compose-completion-enable)

  :config
  ;; Extend the default automated display names with GitLab after
  ;; `bs-mu4e' has initialized its customization variables.
  (unless
      (string-match-p
       bs-mu4e-ignored-contact-display-name-regexp
       "gitlab")
    (setq bs-mu4e-ignored-contact-display-name-regexp
          (concat
           bs-mu4e-ignored-contact-display-name-regexp
           "\\|\\`gitlab\\'"))))

(use-package bs-mu4e
  :after (mu4e-headers)
  :commands (bs-mu4e-headers-enable)

  :init
  ;; Render header `:from' fields with cleaned contact display names
  ;; instead of exposing embedded email addresses in names.
  (bs-mu4e-headers-enable))

(use-package consult-mu
  :functions (consult-mu--view-action)

  :custom
  ;; Use the async mu4e-backed search by default so selected
  ;; candidates keep the normal mu4e header and message actions.
  (consult-mu-default-command 'consult-mu-async)

  ;; Keep enough matches available for broad mailbox searches without
  ;; making the minibuffer completion table unbounded.
  (consult-mu-maxnum 1000)

  ;; Group search results by message date, which keeps recent mail
  ;; easy to scan and can still be overridden with `--group' in input.
  (consult-mu-group-by :date)

  ;; Preview the current candidate immediately while moving through
  ;; completion results.
  (consult-mu-preview-key 'any)

  ;; Do not mark a message as read merely because it was previewed
  ;; during minibuffer navigation.
  (consult-mu-mark-previewed-as-read nil)

  ;; Mark messages as read once they are explicitly opened from the
  ;; search results.
  (consult-mu-mark-viewed-as-read t)

  ;; Open the selected message in the regular mu4e view buffer instead
  ;; of using reply, forward, or a custom action as the default.
  (consult-mu-action 'consult-mu--view-action)

  :bind
  ( :map goto-map
    ;; Put mail search under the standard `goto-map' prefix.
    ("m" . consult-mu)))

(use-package consult-mu-embark
  :after (embark consult-mu)

  ;; Register mail actions only after both Embark and `consult-mu' are
  ;; in use, so loading either one alone does not pull in the other.
  :demand t)

(use-package corfu
  :after (mu4e-compose)

  :hook
  ;; Enable Corfu in compose buffers so CAPF-based recipient
  ;; completion uses the configured popup UI.
  (mu4e-compose-mode-hook . corfu-mode))

(use-package mu4e
  :bind
  ( :map ctl-c-a-map
    ;; Open the `mu4e' mail interface from the custom application map.
    ("m" . mu4e)))

(use-package mu4e-alert
  :after (mu4e)
  :when (eq system-type 'gnu/linux)

  ;; Load alert integration after mu4e is available so message
  ;; notifications can derive their state from the mu4e index.
  :demand t)

(use-package mu4e-alert
  :commands (mu4e-alert-enable-notifications)
  :functions (mu4e-alert-set-default-style)
  :when (eq system-type 'gnu/linux)

  :config
  ;; Use the desktop notification backend for new-message alerts, then
  ;; enable notification delivery once the backend is selected.
  (mu4e-alert-set-default-style 'notifications)
  (mu4e-alert-enable-notifications))

(use-package mu4e-compose
  :hook
  ;; Keep the major-mode label compact in Mu4e compose buffers.
  (mu4e-compose-mode-hook . (lambda ()
                              (setq-local mode-name "Mail"))))

(use-package mu4e-headers
  :defines (mu4e-headers-attach-mark
            mu4e-headers-calendar-mark
            mu4e-headers-draft-mark
            mu4e-headers-encrypted-mark
            mu4e-headers-flagged-mark
            mu4e-headers-list-mark
            mu4e-headers-new-mark
            mu4e-headers-passed-mark
            mu4e-headers-personal-mark
            mu4e-headers-replied-mark
            mu4e-headers-seen-mark
            mu4e-headers-signed-mark
            mu4e-headers-trashed-mark
            mu4e-headers-unread-mark
            mu4e-headers-thread-blank-prefix
            mu4e-headers-thread-child-prefix
            mu4e-headers-thread-connection-prefix
            mu4e-headers-thread-duplicate-prefix
            mu4e-headers-thread-first-child-prefix
            mu4e-headers-thread-last-child-prefix
            mu4e-headers-thread-orphan-prefix
            mu4e-headers-thread-root-prefix
            mu4e-headers-thread-single-orphan-prefix)

  :custom
  ;; Select the fancy side of mark pairs.  Every configured glyph
  ;; below is provided by most fonts, which keeps the header layout
  ;; strictly monospaced without font fallback.
  (mu4e-use-fancy-chars t)

  ;; `:human-date' uses `mu4e-headers-time-format' for today's mail
  ;; and `mu4e-headers-date-format' for older mail, so keep them
  ;; identical.
  (mu4e-headers-date-format "%m/%d/%Y %I:%M:%S %p")
  (mu4e-headers-time-format "%m/%d/%Y %I:%M:%S %p")

  ;; Show compact markers only for flags that distinguish messages.
  ;; Leave out `list' and `personal' because they add no useful
  ;; distinction here, and omit `seen' and `unread' because header
  ;; faces and `new' already expose those states.
  (mu4e-headers-visible-flags '(attach
                                calendar
                                draft
                                encrypted
                                flagged
                                new
                                passed
                                replied
                                signed
                                trashed))

  ;; Keep every non-final field fixed-width. Leave only the last field
  ;; unrestricted.
  (mu4e-headers-fields '(( :flags . 4)
                         ( :human-date . 24)
                         ( :from . 24)
                         ( :subject)))

  ;; Use real padding spaces instead of display-column alignment.
  ;; This keeps copied header rows aligned because `display'
  ;; properties are not preserved when text is copied out of the
  ;; headers buffer.
  (mu4e-headers-precise-alignment nil)

  :init
  ;; These marks are ordinary `defvar' values rather than Custom
  ;; options, so bind them before `mu4e-headers' loads.
  (setq mu4e-headers-draft-mark '("D" . "D")
        mu4e-headers-flagged-mark '("★" . "★")
        mu4e-headers-new-mark '("•" . "•")
        mu4e-headers-passed-mark '("→" . "→")
        mu4e-headers-replied-mark '("←" . "←")
        mu4e-headers-seen-mark '("S" . "S")
        mu4e-headers-trashed-mark '("×" . "×")
        mu4e-headers-attach-mark '("+" . "+")
        mu4e-headers-encrypted-mark '("x" . "x")
        mu4e-headers-signed-mark '("§" . "§")
        mu4e-headers-unread-mark '("◊" . "◊")
        mu4e-headers-list-mark '("=" . "=")
        mu4e-headers-personal-mark '("@" . "@")
        mu4e-headers-calendar-mark '("◦" . "◦"))

  ;; Use three fixed-width cells for every thread-tree level.  These
  ;; box-drawing glyphs are also ordinary `defvar' values.
  (setq mu4e-headers-thread-root-prefix '("*  " . "*  ")
        mu4e-headers-thread-child-prefix '("├─ " . "├─ ")
        mu4e-headers-thread-first-child-prefix '("├─ " . "├─ ")
        mu4e-headers-thread-last-child-prefix '("└─ " . "└─ ")
        mu4e-headers-thread-connection-prefix '("│  " . "│  ")
        mu4e-headers-thread-blank-prefix '("   " . "   ")
        mu4e-headers-thread-orphan-prefix '("╶─ " . "╶─ ")
        mu4e-headers-thread-single-orphan-prefix '("╶─ " . "╶─ ")
        mu4e-headers-thread-duplicate-prefix '("═ " . "═ "))

  :hook
  ;; Keep the major-mode label compact in Mu4e headers buffers.
  (mu4e-headers-mode-hook . (lambda ()
                              (setq-local mode-name "Mail"))))

(use-package mu4e-helpers
  :custom
  ;; Route `mu4e-read-option' through the configured completion
  ;; function instead of mu4e's built-in option reader.
  (mu4e-read-option-use-builtin nil)

  ;; Use the standard completion entry point so the active minibuffer
  ;; completion UI handles mu4e's option prompts.
  (mu4e-completing-read-function 'completing-read))

(use-package mu4e-knockknock
  :after (mu4e)
  :commands (mu4e-knockknock-mode)

  :config
  ;; Enable Knock Knock's mu4e integration once the mail interface is
  ;; available.
  (mu4e-knockknock-mode +1))

(use-package mu4e-main
  :config
  (add-to-list 'display-buffer-alist
               '("\\*mu4e-main\\*"
                 (display-buffer-same-window)))

  :hook
  ;; Keep the major-mode label compact in Mu4e main and info buffers.
  ((mu4e-main-mode-hook
    mu4e-org-mode-hook)
   . (lambda ()
       (setq-local mode-name "Mail"))))

(use-package mu4e-modeline
  :custom
  ;; Disable mu4e's global modeline indicators while keeping
  ;; buffer-specific mu4e modeline information available.
  (mu4e-modeline-show-global nil))

(use-package mu4e-org
  :hook
  ;; Keep the major-mode label compact in Mu4e Org link buffers.
  (mu4e-org-agenda-links-mode-hook
   . (lambda ()
       (setq-local mode-name "Mail"))))

(use-package mu4e-search
  :custom
  ;; Return complete search results so inbox threads retain related
  ;; sent replies after the number of direct matches exceeds Mu4e's
  ;; default result limit.
  (mu4e-search-full t))

(use-package mu4e-thread
  :bind
  ( :map mu4e-thread-mode-map
    ;; Leave `C-<tab>' available outside mu4e-thread by removing this
    ;; mode-specific binding.
    ("C-<tab>" . nil)))

(use-package mu4e-update
  :custom
  ;; Hide annoying "mu4e Retrieving mail..." msg in mini buffer:
  (mu4e-hide-index-messages t)

  ;; Retrieving and indexing messages every 5 minutes.
  (mu4e-update-interval 300)

  :config
  ;; Keep background mail indexing from opening a visible update
  ;; buffer.
  (add-to-list 'display-buffer-alist
               '("\\*mu4e-update\\*"
                 (display-buffer-no-window)
                 (allow-no-window . t)))

  :hook
  ;; Keep the major-mode label compact in Mu4e update buffers.
  (mu4e--update-mail-mode-hook . (lambda ()
                                   (setq-local mode-name "Mail"))))

(use-package mu4e-view
  :hook
  ;; Keep the major-mode label compact in rendered and raw mail views.
  ((mu4e-raw-view-mode-hook
    mu4e-view-mode-hook)
   . (lambda ()
       (setq-local mode-name "Mail"))))

(use-package simple
  :custom
  ;; Route generic Emacs mail entry points, such as `compose-mail', to
  ;; mu4e's compose interface.
  (mail-user-agent 'mu4e-user-agent))

;;
;; Org (info "(org) Top")
;;

(use-package ol
  :custom
  ;; Display links using their description text instead of their raw
  ;; Org syntax.
  (org-link-descriptive t))

(use-package org
  :after (bs-lib)
  :commands (org-set-tags-command)

  :custom
  ;; Directory beneath org files.
  (org-directory (bs-path* "~/org"))

  ;; Restrict agenda discovery to the GTD subtree so agenda commands
  ;; operate on the curated task set instead of every Org file under
  ;; `org-directory'.
  (org-agenda-files (list (bs-path* org-directory "gtd/")
                          (bs-path org-directory "calendar.org")))

  ;; Set the string displayed at folded outline boundaries.  Setting
  ;; this to nil disables the display of a custom ellipsis and lets
  ;; Org fallback to the default three dots.
  (org-ellipsis nil)

  ;; Enable direct TODO state selection for \\`C-c C-t' when shortcut
  ;; keys are defined, and present the available states only in the
  ;; prompt instead of opening the temporary selection window.
  (org-use-fast-todo-selection 'expert)

  ;; Hide the surrounding markup characters for bold, italic,
  ;; verbatim, and similar constructs (e.g. *bold* → bold).  This
  ;; affects only the on-screen representation; the underlying Org
  ;; syntax remains unchanged in the buffer.
  (org-hide-emphasis-markers t)

  ;; Render LaTeX-like entities using their unicode equivalents when
  ;; possible, such as Greek letters, math symbols, and arrows.
  (org-pretty-entities t)

  ;; Enable indentation-based virtual structure when opening Org
  ;; buffers.  This affects only visual presentation and does not
  ;; modify file content.
  (org-startup-indented t)

  ;; Set the column where tags should be aligned.  A negative value
  ;; counts from the right edge of the window, let tags aligned 80
  ;; columns from the right border regardless of window width.
  (org-tags-column -80)
  (org-auto-align-tags t)

  ;; Offer only the execution contexts defined for the GTD workflow:
  ;; required locations, calls, errands, and discussion agendas.
  (org-tag-alist '(("@agenda")
                   ("@errand")
                   ("@home")
                   ("@office")
                   ("@phone")))

  ;; Define a single sequential task workflow with active states
  ;; before `|' and terminal states after it: `TODO' for newly
  ;; captured work, `NEXT' for the next actionable item, `WAIT' for
  ;; blocked work, `DONE' for completed work, `CNCL' for intentionally
  ;; canceled work, and `FAIL' for work that ended unsuccessfully.
  (org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAIT(w)"
                                 "|"
                                 "DONE(d)" "CNCL(c)" "FAIL(f)")))

  :config
  ;; Show the Block Structure dispatcher in a dedicated bottom side
  ;; window and keep it out of normal window cycling, so command
  ;; selection does not disturb the main editing layout.
  (add-to-list 'display-buffer-alist
               '("\\*Org Select\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . fit-window-to-buffer)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t))))))

(use-package org-agenda
  :config
  ;; Show the agenda dispatcher in a dedicated bottom side window and
  ;; keep it out of normal window cycling, so command selection does
  ;; not disturb the main editing layout.
  (add-to-list 'display-buffer-alist
               '("\\*Agenda Commands\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . fit-window-to-buffer)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))))

  ;; Present generated agenda buffers in a predictable bottom side
  ;; window, reusing a fixed slot and limiting height to half the
  ;; frame so surrounding context remains visible.
  (add-to-list 'display-buffer-alist
               '("\\*Org Agenda\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . fit-window-to-buffer))))

(use-package org-appear
  :after (org)

  :hook
  ;; Enable `org-appear-mode' whenever entering Org mode.  This mode
  ;; reveals hidden formatting markers (such as emphasis markers,
  ;; subscript/superscript markers, and link brackets) only when the
  ;; cursor moves onto them.
  (org-mode-hook . org-appear-mode))

(use-package org-capture
  :defines (org-capture-templates))

(use-package org-edna
  :after (org)
  :commands (org-edna-mode)

  :hook
  ;; Enable Org Edna in Org buffers so TODO-state dependencies and
  ;; trigger properties are enforced when tasks change state.
  (org-mode-hook . (lambda ()
                     (org-edna-mode +1))))

(use-package org-gtd
  :preface
  ;; Acknowledge the required Org GTD 4.x upgrade steps up front so
  ;; the package does not emit its one-time migration warning on load.
  (setq org-gtd-update-ack "4.0.0"))

(use-package org-gtd-agenda-transient
  :after (org-agenda)

  :bind
  ( :map org-agenda-mode-map
    ;; Open the Org GTD action menu for the agenda item at point,
    ;; including state, time, clocking, and clarification operations.
    ("C-c ." . org-gtd-agenda-transient)))

(use-package org-gtd-areas-of-focus
  :commands (org-gtd-set-area-of-focus)

  :custom
  ;; Classify GTD projects and actions by the continuing
  ;; responsibility they support, independently of their execution
  ;; context tags.
  (org-gtd-areas-of-focus '("Administration"
                            "Development"
                            "Family"
                            "Finance"
                            "Infrastructure"
                            "Personal"
                            "Research")))

(use-package org-gtd-capture
  :after (bs-ext)
  :defines (org-gtd-capture-templates)

  :bind
  ( :map ctl-c-a-map
    ;; Open the unified capture menu for GTD inbox items and calendar
    ;; events.
    ("c" . org-gtd-capture))

  :hook
  ;; Apply the account-derived calendar settings and start
  ;; change-aware background imports shortly after startup, then make
  ;; the registered event template available through Org GTD capture.
  (bs-after-startup-early-hook
   .
   (lambda ()
     (bs-khal-setup)
     (with-eval-after-load 'org-gtd-capture
       (when-let* ((template
                    (assoc khalel-capture-key org-capture-templates)))
         (add-to-list 'org-gtd-capture-templates template t))))))

(use-package org-gtd-command-center
  :after (bs-ext)

  :bind
  ( :map ctl-c-a-map
    ;; Open the central Org GTD menu for capture, engagement, system
    ;; review, reflection, and archival commands.
    ("g" . org-gtd-command-center)))

(use-package org-gtd-core
  :custom
  ;; Store Org GTD's inbox, archive, and supporting files inside the
  ;; GTD subtree already included in `org-agenda-files'.
  (org-gtd-directory (bs-path* org-directory "gtd/"))

  ;; Bind Org GTD's semantic states to the workflow keywords defined
  ;; above so capture and processing commands follow the same naming,
  ;; including the local `CNCL' spelling for canceled tasks.
  (org-gtd-keyword-mapping '((todo . "TODO")
                             (next . "NEXT")
                             (wait . "WAIT")
                             (done . "DONE")
                             (canceled . "CNCL"))))

(use-package org-gtd-engage
  :after (bs-ext)

  :bind
  ( :map ctl-c-a-map
    ;; Open the org-gtd agenda view focused on actionable work and
    ;; other GTD-specific reviews.
    ("a" . org-gtd-engage)))

(use-package org-gtd-mode
  :after (bs-hooks)

  :hook
  ;; Enable global Org GTD integration shortly after startup,
  ;; including inbox counts, dependency handling, and TODO-state
  ;; maintenance.
  (bs-after-startup-early-hook . org-gtd-mode))

(use-package org-gtd-organize
  :after (org-gtd-clarify)
  :functions (org-gtd-organize-type-member-p)

  :bind
  ( :map org-gtd-clarify-mode-map
    ;; Finish clarifying the current inbox item by opening the
    ;; organizer that assigns its GTD type and files it accordingly.
    ("C-c C-c" . org-gtd-organize)))

(use-package org-gtd-organize-core
  :after (org)

  :config
  ;; Replace the package default, which prompts for tags on every
  ;; item, with type-aware metadata hooks defined below.
  (setq-default org-gtd-organize-hooks nil)

  ;; Prompt for optional execution-context tags only on standalone and
  ;; project actions, calendar items, and habits.
  (add-to-list 'org-gtd-organize-hooks
               #'(lambda ()
                   (when (org-gtd-organize-type-member-p
                          '(next-action calendar habit project-task))
                     (org-set-tags-command))))

  ;; Assign the applicable items to a continuing Area of Focus after
  ;; any execution-context tags have been selected.
  (add-to-list 'org-gtd-organize-hooks 'org-gtd-set-area-of-focus t))

(use-package org-gtd-process
  :after (bs-ext)

  :bind
  ( :map ctl-c-a-map
    ;; Process inbox items sequentially through Org GTD's clarify
    ;; workflow until the configured inbox files are exhausted.
    ("i" . org-gtd-process-inbox)))

(use-package org-gtd-wip
  :after (org-gtd-mode)

  ;; `org-gtd-mode' adds a WIP cleanup function to `kill-emacs-hook'
  ;; without loading its defining library.
  :demand t)

(use-package org-modern
  :after (org)
  :hook
  ;; Activate `org-modern-mode' when entering Org mode.  This adjusts
  ;; the visual presentation of headings, lists, blocks, and tags to
  ;; provide a cleaner and more consistent UI layer.
  (org-mode-hook . org-modern-mode))

(use-package org-modern
  :after (org-agenda)
  :hook
  ;; Enable modern rendering for Org Agenda buffers.  The hook runs
  ;; after the agenda is fully generated, ensuring that all agenda
  ;; lines are replaced with their modern visual counterparts.
  (org-agenda-finalize-hook . org-modern-agenda))

(use-package org-modern-indent
  :after (org)
  :hook
  ;; Add indentation support for `org-modern', aligning visual
  ;; elements with the structural indentation defined by Org.  This
  ;; improves readability without altering underlying Org syntax.
  (org-mode-hook . org-modern-indent-mode))

(use-package org-id
  :custom
  ;; Keep `org-id' location cache next to the configured Org files
  ;; instead of using the default file in the user Emacs directory.
  (org-id-locations-file (bs-path org-directory ".id-locations")))

;;
;; Transparent Remote (file) Access (info "(tramp) Top")
;;

(use-package tramp
  :after (bs-lib)

  :custom
  ;; Automatically save remote files to our local directory, of
  ;; course using our data directory.
  (tramp-auto-save-directory (bs-path bs-data-directory
                                      "tramp/auto-save/"))

  :config
  ;; Let `tramp' use the remote path that assigned to the remote user
  ;; by the remote host.
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(use-package tramp-cache
  :after (bs-lib)

  :custom
  ;; Save the connection history we created with `tramp'.
  (tramp-persistency-file-name (bs-path* bs-state-directory
                                         "tramp/connections.el")))

;;
;; Transient (info "(transient) Top")
;;

(use-package transient
  :after (bs-lib)

  :custom
  ;; Centralizing the storage of `transient' data files to a
  ;; directory under `bs-state-directory'.
  (transient-history-file (bs-path bs-state-directory
                                   "transient"
                                   "history.el"))
  (transient-levels-file  (bs-path bs-state-directory
                                   "transient"
                                   "levels.el"))
  (transient-values-file  (bs-path bs-state-directory
                                   "transient"
                                   "values.el")))

;;; init.el ends here
;; Local Variables:
;; fill-column: 70
;; indent-tabs-mode: nil
;; sentence-end-double-space: t
;; tab-width: 2
;; End:
