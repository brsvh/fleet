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

(eval-when-compile
  (require 'cl-lib)
  (require 'orderless)
  (require 'use-package))



;;
;; use-package (info "(use-package) Top")
;;

(eval-and-compile
  ;; Defer loading of all packages by default.  Each package declared
  ;; with `use-package' will be loaded lazily unless explicitly marked
  ;; otherwise, reducing startup time and making load order explicit.
  (setq use-package-always-defer t
        ;; Keep runtime expansions small.  Build-time byte compilation
        ;; reports configuration errors before activation.
        use-package-expand-minimally t
        ;; Avoid loading `use-package' at startup solely to collect
        ;; diagnostic statistics.
        use-package-compute-statistics nil
        ;; Disable automatic package installation via `use-package'.
        ;; Setting the ensure function to `ignore' prevents
        ;; `use-package' from invoking any package manager, making
        ;; package availability an explicit responsibility of the
        ;; surrounding system configuration.
        use-package-ensure-function #'ignore
        ;; Do not append a suffix to automatically generated hook
        ;; variable names.  This preserves the original hook names
        ;; without modification and avoids implicit renaming.
        use-package-hook-name-suffix nil))



;;
;; The Organization of the Screen (info "(emacs) Screen")
;;

(use-package doom-modeline
  :hook
  ;; Establish the enhanced modeline as part of the normal UI once the
  ;; graphical interface is ready, rather than during early startup.
  (bs-first-ui-hook . doom-modeline-mode))

(use-package doom-modeline-core
  :after (doom-modeline)
  :functions (doom-modeline-remove-segment)

  :custom
  ;; Avoid dedicating vertical space to a rich modeline when the
  ;; window is too narrow, so limited screen width remains focused on
  ;; buffer content rather than status decoration.
  (doom-modeline-window-width-limit 80)

  ;; Keep numeric information in the modeline visually simple and
  ;; unambiguous, avoiding decorative glyphs that may reduce clarity
  ;; or consistency across fonts and environments.
  (doom-modeline-unicode-number nil)

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
  :custom
  ;; Use a simple initial Major Mode to avoid heavy loading overhead.
  (initial-major-mode 'fundamental-mode)

  ;; Let Emacs skip the initial splash screen and splash message on
  ;; startup, so we can taken directly to our editing buffer without
  ;; any introductory distractions.
  (inhibit-startup-screen t)

  :demand t
  :no-require t)



;;
;; Exiting Emacs (info "(emacs) Exiting")
;;

(use-package files
  :custom
  ;; Require explicit confirmation before terminating Emacs.
  (confirm-kill-emacs #'yes-or-no-p))



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
  ;; Bind `cape' prefix keymap providing all `cape' commands under a
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
     ;; Enable `corfu' in the mini-buffer for CAPF-style in-region
     ;; completion, but avoid interfering with completing-read UI
     ;; (`vertico'/`mct') and sensitive input prompts (e.g. password
     ;; entry).
     (unless (or (bound-and-true-p mct--active)
                 (bound-and-true-p vertico--input)
                 (eq (current-local-map) read-passwd-map))
       (corfu-mode +1)))))

(use-package emacs
  :custom
  ;; Allow nested mini buffers.
  (enable-recursive-minibuffers t)

  ;; Drop duplicated history.
  (history-delete-duplicates t)

  ;; Prefer to use `y-or-n-p' to confirm the interactive commands
  ;; requires reconfirmation.
  (use-short-answers t)

  :demand t
  :no-require t)

(use-package embark
  :custom
  ;; Pop up `embark' buffers below the current buffer.
  (embark-verbose-indicator-display-action
   '(display-buffer-reuse-window display-buffer-below-selected))

  :config
  ;; Show the transient `embark' action menu in a dedicated bottom
  ;; side window so action discovery stays visible without replacing
  ;; the current editing window.
  (add-to-list 'display-buffer-alist
               '("\\*Embark Actions\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-parameters . ((no-delete-other-windows . t)
                                       (no-other-window . t)))
                 (window-height . fit-window-to-buffer)))

  ;; Place `embark' collect buffers in a persistent side window on the
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
  ;; Display `marginalia' at right.
  (marginalia-align 'right)

  :hook
  ;; Show `marginalia' of the mini-buffer completions.
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

(use-package orderless
  :custom
  ;; Allow escape with the black-splash.
  (orderless-component-separator 'orderless-escapable-split-on-space))

(use-package savehist
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (savehist-file (bs-path bs-state-directory "history.el"))

  :hook
  ;; Persist our mini-buffer history.
  (bs-first-ui-hook . savehist-mode))

(use-package switch-window
  :after (embark)

  :config
  ;; Exclude `embark' collect helper windows from `switch-window' so
  ;; window selection targets only primary work buffers.
  (add-to-list 'switch-window-ignore-rules
               '(:mode embark-collect-mode)))

(use-package vertico
  :after (bs-hooks)

  :custom
  ;; Resize the `vertico' buffer size when the number of candidates
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
  ;; Ignore `embark' buffers when undo/redo window layout.
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

(use-package emacs
  :custom
  ;; Use `embark-prefix-help-command' to provide the help prompt of
  ;; prefix commands.
  (prefix-help-command 'embark-prefix-help-command))

(use-package embark
  :commands (embark-prefix-help-command))

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
    ;; with a `consult'-based selection interface over the kill ring,
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
  (word-wrap-by-category t)

  :demand t
  :no-require t)

(use-package form-feed
  :commands (form-feed-mode)

  :hook
  (after-change-major-mode-hook
   .
   (lambda ()
     ;; Treat form-feed characters as structural landmarks only in
     ;; buffers that actually contain them.
     (when (save-restriction
             (widen)
             (save-excursion
               (goto-char (point-min))
               (search-forward "\f" nil t)))
       (form-feed-mode +1)))))

(use-package hl-line
  :after (prog-mode)

  :hook
  ;; Highlight the current line.
  (prog-mode-hook . hl-line-mode))

(use-package modus-themes
  :after (bs-hooks)
  :commands (modus-themes-select)

  :custom
  ;; Disable all other themes when loading a `modus-themes' theme.
  (modus-themes-disable-other-themes t)

  ;;Use bold for code syntax highlighting and related.
  (modus-themes-bold-constructs t)

  ;; Use italics for code syntax highlighting and related.
  (modus-themes-italic-constructs t)

  ;; Themes we used.
  (modus-themes-to-toggle '(modus-operandi-tinted
                            modus-vivendi-tinted))

  ;; Use `fixed-pitch' face for `org' tables and code blocks.
  (modus-themes-mixed-fonts t)

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
     (require 'modus-themes)
     (modus-themes-select (or (car modus-themes-to-toggle)
                              'modus-operandi-tinted)))))

(use-package whitespace
  :defines (whitespace-line-column)

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
  (let ((follow-fill-column
         (lambda (&rest _)
           (when (bound-and-true-p whitespace-mode)
             (setq-local whitespace-line-column fill-column)))))
    ;; Keep the visual indication of overlong lines aligned with the
    ;; current column policy, so changes to line width expectations
    ;; are reflected immediately in what is highlighted.
    (add-variable-watcher 'fill-column follow-fill-column)

    ;; Ensure the visual boundary stays consistent whenever whitespace
    ;; highlighting becomes active.
    (add-hook 'whitespace-mode-hook follow-fill-column)))



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
  ;; constituents in the `jinx' syntax table.  This prevents the spell
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
  ;; each file, and automatically prunes excess backups, retaining the
  ;; five oldest and the five most recent versions of each file to
  ;; balance safety with disk usage.
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

  ;; Keep backup files in a single data directory instead of beside
  ;; the files they protect.
  (backup-directory-alist
   `(("." . ,(bs-path* bs-data-directory "backup/"))))

  :config
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
  :after (bs-hooks bs-lib)

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
  ;; Treat `treemacs' as a persistent project sidebar rather than a
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
    ;; Press \\`C-c f d' to open the specified directory in the
    ;; `treemacs' window.
    ("d" . treemacs-select-directory)

    ;; Press \\`C-c f f' to focus the current file in the `treemacs'
    ;; window.
    ("f" . treemacs-find-file)

    ;; The primary entry.
    ("t" . treemacs)

    ;; Focus to the `treemacs' window.
    ("s" . treemacs-select-window)))

(use-package treemacs-bookmarks
  :after (treemacs)

  :bind
  ( :map ctl-c-f-map
    ;; Press \\`C-c f b' to find bookmark.
    ("b" . treemacs-bookmark)))

(use-package treemacs-customization
  :custom
  ;; Favor a dense tree representation to maximize information within
  ;; limited horizontal space.
  (treemacs-indentation 1)

  ;; Prevent `treemacs' from participating in normal window selection,
  ;; reinforcing its role as a fixed navigation panel rather than an
  ;; editing target.
  (treemacs-is-never-other-window t)

  ;; Include hidden files in the tree to reflect the complete project
  ;; structure instead of an opinionated subset.
  (treemacs-show-hidden-files t)

  ;; Persist `treemacs' state across sessions so project context
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
  ;; time, so `treemacs' can be relied on as an accurate
  ;; representation of the current project state during navigation and
  ;; refactoring.
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
  ;; Scope `treemacs' to tabs, treating each tab as an independent
  ;; workspace with its own navigation state.
  (treemacs-set-scope-type 'Tabs))

(use-package treemacs-tab-bar
  :after (treemacs)

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
  :custom
  ;; Resize frame pixel by pixel.
  (frame-resize-pixelwise t)

  :demand t
  :no-require t)

(use-package scroll-bar
  :after (bs-hooks)
  :commands (scroll-bar-mode)

  :hook
  ;; Disable the Scroll Bar for all frames once the UI is initialized.
  (bs-first-ui-hook . (lambda () (scroll-bar-mode -1))))

(use-package tab-bar
  :after (bs-hooks)

  :init
  ;; Only show the Tab Bar when more than one tab exists.  Set the
  ;; value directly because its Custom setter enables `tab-bar-mode'
  ;; immediately, before `bs-first-ui-hook' runs.
  (setq tab-bar-show 1)

  :hook
  ;; Enable `tab-bar-mode'.
  (bs-first-ui-hook . tab-bar-mode))



;;
;; International Character Set Support (info "(emacs) International")
;;

(use-package mule-cmds
  :commands (set-language-environment prefer-coding-system)
  :functions (set-default-coding-systems)

  :init
  ;; Set the default coding system to UTF-8 for new buffers, files and
  ;; sub-process.
  (set-default-coding-systems 'utf-8)

  ;; Configure the language environment to UTF-8 for system messages,
  ;; input methods, and other locale-sensitive features.
  (set-language-environment "utf-8")

  ;; Prefer UTF-8 when negotiating coding systems for files,
  ;; processes, and inter-program communication.
  (prefer-coding-system 'utf-8)

  :demand t
  :no-require t)



;;
;; Major and Minor Modes (info "(emacs) Modes")
;;

(use-package bs-ext
  :hook
  ;; Guess major mode when saving the buffer.
  (after-save-hook . bs/guess-file-major-mode))



;;
;; Indentation (info "(emacs) Indentation")
;;

(use-package electric
  :config
  ;; Indent after \\`<delete>'.
  (add-to-list 'electric-indent-chars ?\^? t))

(use-package electric
  :after prog-mode

  :hook
  ;; Auto re-indentation when programming.
  (prog-mode-hook . electric-indent-local-mode))

(use-package indent
  :custom
  ;; Always complete first using \\`TAB' key.
  (tab-always-indent 'complete)

  :demand t
  :no-require t)



;;
;; Commands for Human Languages (info "(emacs) Text")
;;

(use-package emacs
  :custom
  ;; Set the global default value of `fill-column' to 70 characters.
  ;; This serves as the baseline for line filling and wrapping
  ;; commands, while allowing major modes or hooks to override it
  ;; buffer-locally as needed.
  (fill-column 70)

  :demand t
  :no-require t)

(use-package jieba-rs
  :hook
  ;; Enable Jieba-backed word segmentation in text buffers so CJK
  ;; editing commands can move across natural word boundaries.
  (text-mode-hook . jieba-rs-mode))

(use-package paragraphs
  :custom
  ;; Ensure treat two consecutive spaces after sentence-ending
  ;; punctuation as the canonical sentence boundary.  This affects
  ;; commands such as `forward-sentence', `backward-sentence', and
  ;; filling operations, without modifying the buffer contents or
  ;; inserting extra spaces.
  (sentence-end-double-space t)

  :demand t
  :no-require t)

(use-package simple
  :after (text-mode)

  :hook
  ;; Enable `auto-fill-mode' in Text Mode buffers.
  (text-mode-hook . auto-fill-mode)

  ;; Set the fill column to 80 characters locally for Text Mode
  ;; buffers.
  (text-mode-hook . (lambda ()
                      (setq-local fill-column 80))))



;;
;; Markdown
;;

(use-package bs-edit-indirect
  :after (markdown-mode)
  :defines (markdown-mode-map)

  :bind
  ( :map markdown-mode-map
    ;; Edit the fenced code block at point in a separate buffer.
    ("C-c '" . bs-edit-indirect-markdown-code-block)))

(use-package bs-edit-indirect
  :after (markdown-ts-mode)
  :defines (markdown-ts-mode-map)

  :bind
  ( :map markdown-ts-mode-map
    ;; Edit the fenced code block at point in a separate buffer.
    ("C-c '" . bs-edit-indirect-markdown-code-block)))

(use-package files
  :config
  ;; Replace `markdown-mode' with `markdown-ts-mode' When a buffer
  ;; would normally activate `markdown-mode'.
  (add-to-list 'major-mode-remap-alist
               '(markdown-mode . markdown-ts-mode)
               t))

(use-package grip-mode
  :after (markdown-ts-mode)

  :custom
  ;; Prefer an embedded WebKit preview when Emacs supports xwidgets.
  (grip-preview-in-webkit t)

  :hook
  ;; Start a GitHub-style preview for `markdown-ts-mode' buffers.
  (markdown-ts-mode-hook . grip-mode))

(use-package simple
  :after (markdown-ts-mode)

  :hook
  ;; Enable `auto-fill-mode' in `markdown-ts-mode' buffers.
  (markdown-ts-mode-hook . auto-fill-mode)

  ;; Set the fill column to 80 characters locally for
  ;; `markdown-ts-mode' buffers.
  (markdown-ts-mode-hook . (lambda ()
                             (setq-local fill-column 80))))



;;
;; Org Text
;;

(use-package simple
  :after (org-mode)

  :hook
  ;; Enable `auto-fill-mode' in `org-mode' buffers.
  (org-mode-hook . auto-fill-mode)

  ;; Set the fill column to 80 characters locally for `org-mode'
  ;; buffers.
  (org-mode-hook . (lambda ()
                     (setq-local fill-column 80))))



;;
;; Editing Programs (info "(emacs) Programs")
;;

(use-package apheleia
  :after (prog-mode)

  :hook
  ;; `apheleia' formats code using external formatter via a
  ;; non-blocking pipeline, typically on save, without interfering
  ;; with interactive editing or modifying buffers outside explicit
  ;; formatting events.
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

  :custom
  ;; Enable our `citre' back-ends.
  (citre-auto-enable-citre-mode-backends '(global tags))

  ;; Let auto enabling `citre-mode' behavior work for certain modes.
  (citre-auto-enable-citre-mode-modes '(prog-mode))

  :bind
  ( :map ctl-c-c-map
    ;; Jump to the definition at point using the tags database when
    ;; press \\`C-c c j'.
    ("j" . citre-jump)

    ;; Peek definitions at point using an ace-style selection
    ;; interface when press \\`C-c c p', without leaving the current
    ;; buffer.
    ("p" . citre-ace-peek)))

(use-package citre-config
  :demand t)

(use-package citre-ctags
  :after (citre)

  :custom
  ;; Always use one location to create a tags file.
  (citre-default-create-tags-file-location 'global-cache)

  ;; Use ctags options generated by `citre' directly, rather than
  ;; editing them further.
  (citre-edit-ctags-options-manually nil)

  :bind
  ( :map ctl-c-c-map
    ;; Update the tags file associated with the current buffer or
    ;; project context when press \\`C-c c u'.
    ("u" . citre-update-this-tags-file)))

(use-package citre-ui-jump
  :after (citre)

  :bind
  ( :map ctl-c-c-map
    ;; Jump back to the previous location in the `citre' jump stack
    ;; when press \\`C-c c J'.
    ("J" . citre-jump-back)))

(use-package consult-eglot-embark
  :after (eglot embark)

  :hook
  ;; Enable `consult-eglot-embark-mode' for buffers managed by
  ;; `eglot'.
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
    ;; Query a text and search it in the all info manuals, instead of
    ;; opening the index.
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
  ;; Sort `corfu' candidates by history.
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
  ;; Enhance `eglot' communication and processing pipeline to reduce
  ;; latency and improve responsiveness, without changing LSP
  ;; semantics or server behavior.
  (eglot-managed-mode-hook . eglot-booster-mode))

(use-package eldoc-box
  :after (eldoc)

  :hook
  ;; Display `eldoc' documentation in a child frame near point on
  ;; hover, providing contextual information without using the echo
  ;; area or modifying buffer content.
  (eldoc-mode-hook . eldoc-box-hover-at-point-mode))

(use-package hideshow
  :after (prog-mode)

  :hook
  ;; Allow folding and unfolding of code blocks.
  (prog-mode-hook . hs-minor-mode))

(use-package hl-todo
  :defines (hl-todo-keyword-faces)

  :config
  (let ((set-keyword-faces
         (lambda ()
           (when (featurep 'hl-todo)
             (dolist (entry '(("CNCL" . warning)
                              ("WAIT" . warning)))
               (setf (alist-get (car entry)
                                hl-todo-keyword-faces
                                nil
                                nil
                                #'string=)
                     (cdr entry)))))))
    ;; Apply local keyword face overrides when `hl-todo' first loads.
    (funcall set-keyword-faces)

    ;; Reapply the overrides after each `modus-themes' theme load, but
    ;; only when `hl-todo' has already been used.
    (add-hook 'modus-themes-after-load-theme-hook set-keyword-faces))

  :hook
  ;; Treat TODO markers as active signals during development, not
  ;; passive comments to be rediscovered later.
  (prog-mode-hook . hl-todo-mode))

(use-package nerd-icons-corfu
  :after (corfu)
  :commands (nerd-icons-corfu-formatter)

  :custom
  ;; Support faster completion decisions by encoding semantic hints
  ;; visually, so candidate type recognition does not rely solely on
  ;; reading text.
  (corfu-margin-formatters '(nerd-icons-corfu-formatter)))

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



;;
;; C/C++ Programs
;;

(use-package c-ts-mode
  :commands (c-ts-mode c++-ts-mode))

(use-package eglot
  :after (cc-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for classic C/C++
  ;; major modes derived from `cc-mode'.
  ((c-mode-hook c++-mode-hook c-or-c++-mode-hook)
   .
   eglot-ensure))

(use-package eglot
  :after (c-ts-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Tree-sitter
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



;;
;; Common Lisp Programs
;;

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
  ;; Load `sly' contrib packages before running `sly'.
  (advice-add 'sly :before 'sly-setup)

  :config
  ;; Register the `sly' contrib packages we want to use.
  (dolist (feature '(sly-asdf
                     sly-macrostep
                     sly-named-readtables
                     sly-stepper))
    (add-to-list 'sly-contribs feature t)))

(use-package sly-completion
  :custom
  ;; Use the standard completion UI instead of the global,
  ;; Lisp-specific symbol completion interface from `sly'.
  (sly-symbol-completion-mode nil))

(use-package sly-mrepl
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (sly-mrepl-history-file-name
   (bs-path* bs-state-directory "sly/mrepl-history.el")))



;;
;; Emacs Lisp Programs
;;

(use-package paredit
  :after (elisp-mode)

  :hook
  ;; Enable structured editing to enforcing balanced parentheses and
  ;; S-expression integrity by `paredit'.
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



;;
;; Haskell Programs
;;

(use-package eglot
  :after (haskell-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Haskell
  ;; buffers.
  (haskell-mode-hook . eglot-ensure))

(use-package eglot
  :after (haskell-ts-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Tree-sitter
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



;;
;; JavaScript Programs
;;

(use-package eglot
  :after (js)

  :config
  ;; Use TypeScript 7's native language server for JavaScript and JSX
  ;; buffers.
  (add-to-list 'eglot-server-programs
               '(((js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript"))
                 .
                 ("tsc" "--lsp" "--stdio")))

  :hook
  ;; Automatically start or reuse an `eglot' session for JavaScript
  ;; buffers.
  ((js-mode-hook js-ts-mode-hook)
   .
   eglot-ensure))

(use-package files
  :config
  ;; Replace `js-mode' with `js-ts-mode' when a buffer would normally
  ;; activate `js-mode'.
  (add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode) t))

(use-package js
  :mode
  ;; Associate JavaScript source files with `js-mode'.
  ("\\.\\(?:[cm]?js\\|jsx\\)\\'" . js-mode))



;;
;; JSON Programs
;;

(use-package eglot
  :after (js-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for JSON buffers.
  (js-json-mode-hook . eglot-ensure))

(use-package eglot
  :after (json-ts-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Tree-sitter
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



;;
;; Nix Programs
;;

(use-package bs-edit-indirect
  :after (nix-mode)
  :defines (nix-mode-map)

  :bind
  ( :map nix-mode-map
    ;; Edit the literal string at point in a separate buffer.
    ("C-c '" . bs-edit-indirect-nix-literal-string)))

(use-package bs-edit-indirect
  :after (nix-ts-mode)
  :defines (nix-ts-mode-map)

  :bind
  ( :map nix-ts-mode-map
    ;; Edit the literal string at point in a separate buffer.
    ("C-c '" . bs-edit-indirect-nix-literal-string)))

(use-package eglot
  :after (nix-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Nix buffers.
  (nix-mode-hook . eglot-ensure))

(use-package eglot
  :after (nix-ts-mode)

  :hook
  ;; Automatically start or reuse an `eglot' session for Tree-sitter
  ;; Nix buffers.
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



;;
;; Python Programs
;;

(use-package eglot
  :after (python)

  :hook
  ;; Automatically start or reuse an `eglot' session for Python
  ;; buffers.
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



;;
;; Scheme Programs
;;

(use-package geiser-repl ;; (info "(geiser) Top")
  :after (bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (geiser-repl-history-filename (bs-path bs-state-directory
                                         "geiser_history")))

(use-package macrostep-geiser
  :after (geiser-mode)

  :hook
  ;; Expand Scheme macros through Geiser in source buffers.
  (geiser-mode-hook . macrostep-geiser-setup))

(use-package macrostep-geiser
  :after (geiser-repl)

  :hook
  ;; Expand Scheme macros through Geiser in REPL buffers.
  (geiser-repl-mode-hook . macrostep-geiser-setup))



;;
;; TypeScript Programs
;;

(use-package eglot
  :after (typescript-ts-mode)

  :config
  ;; Use TypeScript 7's native language server for TypeScript and TSX
  ;; buffers.
  (add-to-list 'eglot-server-programs
               '(((typescript-ts-mode :language-id "typescript")
                  (tsx-ts-mode :language-id "typescriptreact"))
                 .
                 ("tsc" "--lsp" "--stdio")))

  :hook
  ;; Automatically start or reuse an `eglot' session for TypeScript
  ;; and TSX buffers.
  ((typescript-ts-mode-hook tsx-ts-mode-hook)
   .
   eglot-ensure))

(use-package typescript-ts-mode
  :mode
  ;; Associate TypeScript source files with their Tree-sitter modes.
  ("\\.[cm]?ts\\'" . typescript-ts-mode)
  ("\\.tsx\\'" . tsx-ts-mode))



;;
;; Compiling and Testing Programs (info "(emacs) Building")
;;

(use-package consult-flymake
  :after (flymake)

  :bind
  ( :map flymake-mode-map
    ;; Show `flymake' diagnostics when pressing \\`C-c !'.
    ("C-c !" . consult-flymake)))

(use-package flymake
  :after (prog-mode)

  :hook
  ;; Enable `flymake'.
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
  :custom
  ;; Clearing the *scratch* buffer.
  initial-scratch-message nil

  :demand t
  :no-require t)



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
  ;; Synchronize `diff-hl' after the `magit' auto-revert pass, so file
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

(use-package envrc
  :after (bs-hooks)

  :hook
  ;; Enable `envrc-global-mode' when the first file is visited.  This
  ;; activates direnv-based environment loading for all subsequent
  ;; buffers, ensuring that project-local environment variables are
  ;; applied automatically without affecting startup performance.
  (bs-first-file-hook . envrc-global-mode))

(use-package ghostel-dwim
  :after (project)

  :bind
  ( :map global-map
    ;; Use `ghostel' to create shell based on project root.
    ([remap project-shell] . ghostel-dwim-project)

    :map ctl-c-p-map
    ;; Switch to a `ghostel' buffer associated with the current
    ;; project.
    ("C-s" . ghostel-dwim-project-switch)

    ;; Reuse an idle `ghostel' session for the current project or
    ;; create one.
    ("s" . ghostel-dwim-project)))

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
  ;; Disable the global key bindings from `magit'.
  (magit-define-global-key-bindings nil))

(use-package magit-autorevert
  :after (magit)
  :commands (magit-auto-revert-mode)

  :init
  ;; Enable repository-aware auto-revert only after `magit' is first
  ;; loaded, keeping the integration out of the startup path.
  (magit-auto-revert-mode +1))

(use-package magit-status
  :config
  ;; Show `magit-status' in the shared bottom side window used for
  ;; commit message editing.
  (add-to-list 'display-buffer-alist
               '((derived-mode . magit-status-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)))

  :bind
  ( :map ctl-c-v-map
    ;; Press \\`C-c v g' to display `magit'.
    ("g" . magit)))

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

(use-package treemacs-git-commit-diff-mode
  :after (treemacs)
  :commands (treemacs-git-commit-diff-mode)

  :init
  ;; Make commit diffs visible in relation to the project tree, so
  ;; changes introduced by a commit can be understood in their
  ;; directory context rather than as an isolated list of files.
  (treemacs-git-commit-diff-mode +1))

(use-package treemacs-magit
  :after (magit treemacs)

  :demand t)

(use-package treemacs-project-follow-mode
  :after (treemacs)
  :commands (treemacs-project-follow-mode)

  :init
  ;; Keep the active `treemacs' project aligned with the project of
  ;; the current buffer, so navigation always reflects the context
  ;; being worked on rather than a previously selected tree.
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
  ;; when working across multiple `dired' buffers.
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

(use-package bs-khal
  :after (bs-ext)
  :commands (bs-khal-capture
             bs-khal-import-events
             bs-khal-setup)

  :custom
  ;; Check the calendar sources every five minutes, importing only
  ;; when their persisted state differs from the last successful run.
  (bs-khal-import-check-interval 300))

(use-package calfw-org
  :after (org)
  :commands (calfw-org-open-calendar)

  :bind
  ( :map ctl-c-a-map
    ;; Open a calendar view backed by the same `org' files used by the
    ;; agenda.  Press \\`v w' or \\`v m' there to switch between week
    ;; and month views.
    ("k" . calfw-org-open-calendar)))

(use-package khalel
  :defines (khalel-capture-key)

  :custom
  ;; Use \\`c' for calendar events in the `org' capture menu.
  (khalel-capture-key "c")

  ;; Include events up to ninety days in the future in the generated
  ;; `org' calendar mirror.
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

  ;; Store the generated calendar mirror alongside the other `org'
  ;; data.
  (khalel-import-org-file
   (bs-path* org-directory "calendar.org"))

  ;; Replace the generated mirror without prompting, since it contains
  ;; imported data rather than user-authored entries.
  (khalel-import-org-file-confirm-overwrite nil)

  ;; Protect imported entries from accidental edits; changes should be
  ;; made through `khalel' or the source calendar.
  (khalel-import-org-file-read-only t)

  ;; Include the previous seven days so recent events remain available
  ;; in agenda and calendar views.
  (khalel-import-start-date "-7d")

  ;; Keep remote synchronization independent from event capture.
  (khalel-run-vdirsyncer-after-capture nil))



;;
;; Sending Mail (info "(emacs) Sending Mail")
;;

(use-package message
  :commands (message-mail-p))

(use-package mml-sec
  :after (message)
  :commands (mml-secure-message-sign-pgpmime)

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
  ;; Sign outgoing mail with PGP/MIME by default, while leaving Usenet
  ;; articles unsigned.
  (message-setup-hook
   .
   (lambda ()
     (when (message-mail-p)
       (mml-secure-message-sign-pgpmime)))))



;;
;; Reading Mail with Rmail (info "(emacs) Rmail")
;;



;;
;; Email and Usenet News with Gnus (info "(emacs) Gnus")
;;

(use-package auth-source-pass
  :after (gnus)
  :commands (auth-source-pass-enable)

  :init
  ;; Activate the password-store backend as soon as `gnus' loads, so
  ;; the first interactive `gnus' command can resolve NNTP
  ;; credentials.
  (auth-source-pass-enable))

(use-package bs-gnus
  :after (gnus gnus-notifications gravatar)
  :commands (bs-gnus-group-enable
             bs-gnus-prepare-today-context
             bs-gnus-group-posting-status
             bs-gnus-group-topic-toggle
             bs-gnus-notifications-enable
             bs-gnus-summary-enable
             bs-gnus-summary-fold-toggle
             bs-gnus-summary-next
             bs-gnus-summary-previous
             bs-gnus-update
             bs-gnus-update-enable)
  :defines (gnus-group-mode-map
            gnus-summary-mode-map)
  :functions (bs-gnus--group-display-name
              bs-gnus--group-display-name@shorten-gmane-prefix)

  :custom
  ;; Name NNTP sources by their configured server addresses in the
  ;; Group buffer.
  (bs-gnus-group-source-names
   '(("news.eternal-september.org" . "Eternal September")
     ("news.gmane.io" . "Gmane")
     ("news.solani.org" . "Solani")))

  ;; Check for new articles every five minutes so each background
  ;; update produces a smaller burst of desktop notifications.
  (bs-gnus-update-interval (* 5 60))

  ;; Follow Summary navigation in an already visible Article window
  ;; without opening one solely for movement.
  (bs-gnus-summary-follow-visible-article t)

  ;; Right-align complete thread counts through `999/999+', keeping
  ;; subjects in a stable column.
  (bs-gnus-summary-thread-count-digits 8)

  ;; Keep worker-fetched notification avatars across sessions while
  ;; treating them as stale after 90 days.
  (bs-gnus-notifications-avatar-cache-directory
   (bs-path bs-cache-directory "gnus/notification-avatars/"))
  (bs-gnus-notifications-avatar-cache-expiry (* 90 24 60 60))

  ;; Open each notification Read action in a new frame belonging to
  ;; the current Emacs session.
  (bs-gnus-notifications-read-display-function
   #'bs-call-in-new-frame)

  :config
  ;; Omit the redundant Gmane namespace from visible group names.
  (define-advice bs-gnus--group-display-name
      (:filter-return (name) shorten-gmane-prefix)
    "Omit the leading Gmane namespace from visible group NAME."
    (string-remove-prefix "gmane." name))

  ;; Replace the native Group and Summary layouts only after `gnus'
  ;; itself loads, and keep remote updates outside the main Emacs
  ;; process.
  (bs-gnus-group-enable)
  (bs-gnus-summary-enable)
  (bs-gnus-notifications-enable)
  (bs-gnus-update-enable)

  :bind
  ( :map gnus-group-mode-map
    ;; Prepare today's locally cached articles from all subscribed
    ;; groups as LLM context.
    ("C-c m t" . bs-gnus-prepare-today-context)

    :map gnus-summary-mode-map
    ;; Prepare today's locally cached articles from all subscribed
    ;; groups as LLM context.
    ("C-c m t" . bs-gnus-prepare-today-context)

    ;; Prepare the current article and its replies as LLM context.
    ("C-c m m" . bs-gnus-summary-prepare-subthread-context))

  :demand t)

(use-package bs-gnus
  :after (gnus-topic)
  :defines (gnus-topic-mode-map)

  :bind
  ( :map gnus-topic-mode-map
    ;; Fold or expand the topic at point without changing hierarchy.
    ("TAB" . bs-gnus-group-topic-toggle)
    ("<tab>" . bs-gnus-group-topic-toggle)))

(use-package gnus
  :after (bs-lib)
  :commands (gnus)
  :defines (gnus-select-method)

  :custom
  ;; Store `gnus' state beneath the shared Emacs state directory.
  (gnus-home-directory (bs-path bs-state-directory "gnus/"))

  ;; Store drafts, scores, and other persistent `gnus' data separately
  ;; from runtime state.
  (gnus-directory (bs-path bs-data-directory "gnus/"))

  ;; Limit the initial Summary for NNTP groups, download short Eternal
  ;; September articles on explicit Agent requests, and require
  ;; explicit download marks for Gmane articles.  Treat subscribed
  ;; Gmane archives as mailing lists: `to-list' routes ordinary
  ;; followups through SMTP without discarding the author or Cc
  ;; recipients, while new messages go to the authoritative list
  ;; address.
  (gnus-parameters
   (append
    '(("\\`\\(?:comp\\.\\|nntp\\+gmane:\\)"
       (display . 100))
      ("\\`comp\\."
       (agent-predicate . short))
      ("\\`nntp\\+gmane:"
       (agent-predicate . false)))
    (mapcar
     (lambda (entry)
       (list
        (concat
         "\\`nntp\\+gmane:"
         (regexp-quote (car entry))
         "\\'")
        (cons 'to-list (cdr entry))
        '(subscribed . t)))
     '(("gmane.comp.gcc.devel"
        .
        "gcc@gcc.gnu.org")
       ("gmane.comp.gdb.devel"
        .
        "gdb@sourceware.org")
       ("gmane.comp.gnu.binutils"
        .
        "binutils@sourceware.org")
       ("gmane.comp.hardware.riscv.isa.devel"
        .
        "isa-dev@groups.riscv.org")
       ("gmane.comp.hardware.riscv.opensbi.devel"
        .
        "opensbi@lists.infradead.org")
       ("gmane.comp.lib.glibc.alpha"
        .
        "libc-alpha@sourceware.org")
       ("gmane.emacs.devel"
        .
        "emacs-devel@gnu.org")
       ("gmane.emacs.help"
        .
        "help-gnu-emacs@gnu.org")
       ("gmane.linux.ports.riscv"
        .
        "linux-riscv@lists.infradead.org")
       ("gmane.lisp.asdf.devel"
        .
        "asdf-devel@lists.common-lisp.net")
       ("gmane.lisp.guile.devel"
        .
        "guile-devel@gnu.org")
       ("gmane.lisp.guile.user"
        .
        "guile-user@gnu.org")
       ("gmane.lisp.scheme.chez"
        .
        "chez-scheme@googlegroups.com")
       ("gmane.lisp.scheme.mit-scheme.devel"
        .
        "mit-scheme-devel@gnu.org")))))

  ;; Keep the Gmane mailing-list archive available as a secondary NNTP
  ;; source, upgrading its standard connection with STARTTLS.
  (gnus-secondary-select-methods
   '((nntp "gmane"
           (nntp-address "news.gmane.io")
           (nntp-port-number 119)
           (nntp-open-connection-function
            nntp-open-network-stream))
     (nntp "solani"
           (nntp-address "news.solani.org")
           (nntp-port-number 563)
           (nntp-open-connection-function nntp-open-tls-stream)
           (nntp-authinfo-force t))))

  ;; Mark articles selected for later batch processing with a hash.
  (gnus-process-mark ?#)

  :config
  ;; Load the declarative subscription and topic state after `gnus'
  ;; has restored its machine-local newsrc state, then retire this
  ;; one-shot hook for the rest of the Emacs session.
  (let (load-config)
    (setq load-config
          (lambda ()
            (let ((config
                   (bs-path bs-config-directory "gnus.el")))
              (when (file-exists-p config)
                (load config nil t t)
                (remove-hook 'gnus-setup-news-hook
                             load-config)))))
    (add-hook 'gnus-setup-news-hook load-config))

  ;; Use authenticated, encrypted Eternal September access for normal
  ;; Usenet reading and posting.
  (setq gnus-select-method
        '(nntp "eternal-september"
               (nntp-address "news.eternal-september.org")
               (nntp-port-number 563)
               (nntp-open-connection-function nntp-open-tls-stream)
               (nntp-authinfo-force t)))

  :bind
  ( :map ctl-c-a-map
    ;; Start `gnus' explicitly; loading this init file performs no
    ;; NNTP connection, active-file scan, or `gnus' state
    ;; initialization.
    ("n" . gnus)))

(use-package gnus-agent
  :after (gnus)
  :defines (gnus-agent-predicate)

  :custom
  ;; Cache NNTP data separately from persistent read and subscription
  ;; state.
  (gnus-agent-directory
   (bs-path bs-cache-directory "gnus/agent/"))

  ;; Agentize all NNTP methods automatically when their servers are
  ;; first registered.
  (gnus-agent-auto-agentize-methods '(nntp))

  ;; Apply the Agent predicate only to unread articles instead of
  ;; reconsidering the complete group history.
  (gnus-agent-consider-all-articles nil)

  ;; Preserve all downloaded articles regardless of their read state.
  (gnus-agent-enable-expiration 'DISABLE)

  :init
  ;; This predicate is an ordinary `defvar', so bind it before
  ;; `gnus-agent' loads instead of passing it through Custom.
  (setq gnus-agent-predicate 'false))

(use-package gnus-art
  :after (gnus)
  :defines (gnus-article-mode-map))

(use-package gnus-async
  :after (gnus)

  :custom
  ;; Prefetch articles over a second connection while the current
  ;; article is being read.
  (gnus-asynchronous t)

  ;; Limit asynchronous work to the next ten articles.
  (gnus-use-article-prefetch 10)

  ;; Avoid prefetching articles that have already been read.
  (gnus-async-prefetch-article-p #'gnus-async-unread-p))

(use-package gnus-group
  :after (gnus)

  :custom
  ;; Leave only the group name in native rows; `bs-gnus' supplies the
  ;; responsive count, status, and source fields after preparation.
  (gnus-group-line-format "%P%g\n")

  ;; Keep every subscribed group visible even when it has no unread
  ;; articles.
  (gnus-permanently-visible-groups ".*")

  ;; Keep groups alphabetical by their displayed, backend-unprefixed names.
  (gnus-group-sort-function 'gnus-group-sort-by-real-name)

  :hook
  ;; Use a concise mode-line name for `gnus-group' buffers.
  (gnus-group-mode-hook . (lambda ()
                            (setq-local mode-name "News Groups"))))

(use-package gnus-msg
  :after (gnus)

  :custom
  ;; Generate Mail-Followup-To from the Gmane groups explicitly
  ;; marked as subscribed above.
  (message-subscribed-address-functions
   '(gnus-find-subscribed-addresses)))

(use-package gnus-notifications
  :after (gnus)

  :custom
  ;; Notify articles from every subscribed group and leave each
  ;; actionable notification visible for fifteen seconds.
  (gnus-notifications-minimum-level 5)
  (gnus-notifications-timeout (* 15 1000))

  ;; Resolve sender images through Gravatar only.
  (gnus-notifications-use-google-contacts nil)
  (gnus-notifications-use-gravatar t)

  :demand t)

(use-package gnus-start
  :after (gnus)

  :custom
  ;; Keep subscriptions, read ranges, and topic state with the other
  ;; persistent Emacs state.
  (gnus-startup-file (bs-path bs-state-directory "gnus/newsrc"))

  ;; Keep all `gnus' configuration in this init file instead of
  ;; loading a separate user `gnus' file.
  (gnus-init-file nil)

  ;; Do not load site-wide `gnus' configuration outside this
  ;; controlled setup.
  (gnus-site-init-file nil)

  ;; Discover newly created groups only on explicit request instead of
  ;; querying every server when `gnus' starts.
  (gnus-check-new-newsgroups nil)

  ;; Read only the active data needed for subscribed and requested
  ;; groups instead of downloading each server's complete active file.
  (gnus-read-active-file 'some))

(use-package gnus-sum
  :after (gnus)
  :defines (gnus-summary-mode-map)
  :functions (gnus-summary-select-article-buffer)

  :custom
  ;; Display conversations as threads, matching threaded `mu4e'
  ;; searches.
  (gnus-show-threads t)

  ;; Use only `hl-line' to highlight the current Summary row; do not
  ;; retain a second highlight for the displayed article.
  (gnus-summary-selected-face nil)

  ;; Extend a limited Summary on demand when article movement reaches
  ;; beyond its current boundary.
  (gnus-auto-extend-newsgroup t)

  ;; Retrieve enough older headers to reconnect incomplete threads.
  (gnus-fetch-old-headers 'some)

  ;; Fill only the missing reference nodes needed to connect otherwise
  ;; incomplete threads.
  (gnus-build-sparse-threads 'some)

  ;; Order threads by their root article dates so month separators
  ;; form contiguous chronological sections.
  (gnus-thread-sort-functions
   '(gnus-thread-sort-by-number
     (not gnus-thread-sort-by-date)))

  ;; Keep articles within each thread in chronological order.
  (gnus-subthread-sort-functions
   '(gnus-thread-sort-by-number
     gnus-thread-sort-by-date))

  ;; Mark unread articles with the same bullet used by Elfeed Search.
  (gnus-unread-mark ?•)

  ;; Mark articles retained for later attention with a star.
  (gnus-ticked-mark ?★)

  ;; Mark dormant articles with a quiet hollow bullet.
  (gnus-dormant-mark ?◦)

  ;; Mark manually dismissed articles with a minus sign.
  (gnus-del-mark ?−)

  ;; Leave articles read during the current session visually quiet.
  (gnus-read-mark ?\s)

  ;; Mark articles read in earlier sessions with a middle dot.
  (gnus-ancient-mark ?·)

  ;; Mark articles eligible for expiration with a tilde.
  (gnus-expirable-mark ?~)

  ;; Identify articles removed by an explicit kill operation.
  (gnus-killed-mark ?K)

  ;; Highlight articles classified as spam with an exclamation mark.
  (gnus-spam-mark ?!)

  ;; Identify articles excluded by kill-file rules with inequality.
  (gnus-kill-file-mark ?≠)

  ;; Mark articles read because their score fell below the threshold.
  (gnus-low-score-mark ?≤)

  ;; Mark articles skipped by catch-up operations with a double angle.
  (gnus-catchup-mark ?»)

  ;; Mark sparse thread references with an ellipsis.
  (gnus-sparse-mark ?…)

  ;; Mark canceled articles with a multiplication sign.
  (gnus-canceled-mark ?×)

  ;; Mark articles suppressed as duplicates with an equals sign.
  (gnus-duplicate-mark ?=)

  ;; Identify articles stored in the `gnus' article cache with `C'.
  (gnus-cached-mark ?C)

  ;; Mark replied articles with a left arrow, matching `mu4e'.
  (gnus-replied-mark ?←)

  ;; Mark forwarded articles with a right arrow, matching `mu4e'.
  (gnus-forwarded-mark ?→)

  ;; Identify articles saved outside their group with `S'.
  (gnus-saved-mark ?S)

  ;; Mark articles not previously seen by `gnus' with a hollow diamond.
  (gnus-unseen-mark ?◊)

  ;; Identify recently arrived articles with `N'.
  (gnus-recent-mark ?N)

  ;; Reserve a blank cell when no auxiliary article mark applies.
  (gnus-no-mark ?\s)

  ;; Mark articles available through the Agent with a down arrow.
  (gnus-downloaded-mark ?↓)

  ;; Mark articles unavailable to the Agent with a minus sign.
  (gnus-undownloaded-mark ?−)

  ;; Mark articles explicitly queued for Agent download with a plus.
  (gnus-downloadable-mark ?+)

  ;; Mark articles that the Agent cannot send with multiplication.
  (gnus-unsendable-mark ?×)

  ;; Mark scores above the group default with an upward arrow.
  (gnus-score-over-mark ?↑)

  ;; Mark scores below the group default with a downward arrow.
  (gnus-score-below-mark ?↓)

  ;; Reserve a blank marker for threads without descendants.
  (gnus-empty-thread-mark ?\s)

  ;; Mark threads containing descendants with a plus sign.
  (gnus-not-empty-thread-mark ?+)

  ;; Prefix each real thread root with a compact asterisk branch.
  (gnus-sum-thread-tree-root "*  ")

  ;; Render synthesized thread roots like real roots.
  (gnus-sum-thread-tree-false-root "*  ")

  ;; Render single-message thread indentation like a root branch.
  (gnus-sum-thread-tree-single-indent "*  ")

  ;; Draw continuing ancestor branches with a vertical box line.
  (gnus-sum-thread-tree-vertical "│  ")

  ;; Reserve three columns for an inactive ancestor branch.
  (gnus-sum-thread-tree-indent "   ")

  ;; Draw non-final children with a branching box line.
  (gnus-sum-thread-tree-leaf-with-other "├─ ")

  ;; Draw final children with a terminating box line.
  (gnus-sum-thread-tree-single-leaf "└─ ")

  :config
  ;; Display the current article and move focus into its window,
  ;; instead of scrolling it remotely from the Summary buffer.
  (keymap-set gnus-summary-mode-map
              "RET" #'gnus-summary-select-article-buffer)
  (keymap-set gnus-summary-mode-map
              "<return>" #'gnus-summary-select-article-buffer)

  ;; Move between concrete articles rather than decoration lines.
  (keymap-set gnus-summary-mode-map "n" #'bs-gnus-summary-next)
  (keymap-set gnus-summary-mode-map "p" #'bs-gnus-summary-previous)
  (keymap-set gnus-summary-mode-map "M-<down>" #'bs-gnus-summary-next)
  (keymap-set gnus-summary-mode-map "M-<up>" #'bs-gnus-summary-previous)

  ;; Fold or expand replies to the current article.
  (keymap-set gnus-summary-mode-map "TAB" #'bs-gnus-summary-fold-toggle)
  (keymap-set gnus-summary-mode-map "<tab>" #'bs-gnus-summary-fold-toggle)

  :hook
  ;; Use a concise mode-line name for `gnus-sum' buffers.
  (gnus-summary-mode-hook . (lambda ()
                              (setq-local mode-name "News"))))

(use-package gnus-topic
  :after (gnus)
  :defines (gnus-topic-mode-map)

  :custom
  ;; Leave only indentation and the topic name in native rows;
  ;; `bs-gnus' supplies fold indicators and unread counts.
  (gnus-topic-line-format "%i%n\n")

  ;; Hide configured topics that contain no visible groups.
  (gnus-topic-display-empty-topics nil)

  ;; Indent each topic hierarchy level by two columns.
  (gnus-topic-indent-level 2)

  :bind
  ( :map gnus-topic-mode-map
    ;; Keep hierarchy changes behind explicit topic-prefix keys.
    ("T >" . gnus-topic-indent)
    ("T <" . gnus-topic-unindent)
    ("T TAB" . nil))

  :hook
  ;; Organize subscribed groups into collapsible topics in the normal
  ;; `gnus-group' buffer.
  (gnus-group-mode-hook . gnus-topic-mode))

(use-package gnus-win
  :after (gnus)

  :custom
  ;; Preserve unrelated windows and confine `gnus' layouts to the
  ;; window from which `gnus' was entered.
  (gnus-use-full-window nil))

(use-package gptel-transient
  :after (gnus-group)

  :bind
  ( :map gnus-group-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)))

(use-package gptel-transient
  :after (gnus-sum)

  :bind
  ( :map gnus-summary-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)))

(use-package gravatar
  :after (gnus-notifications)

  :custom
  ;; Treat an address without a Gravatar as having no image instead
  ;; of generating a fallback avatar.
  (gravatar-default-image "404")

  ;; Request compact images suitable for desktop notifications.
  (gravatar-size 32)

  :demand t)

(use-package hl-line
  :after (gnus-group)

  :hook
  ;; Highlight the current Group row without changing its contents.
  (gnus-group-mode-hook . hl-line-mode))

(use-package hl-line
  :after (gnus-sum)

  :hook
  ;; Highlight the Summary row at point independently of the article
  ;; displayed in the Article buffer.
  (gnus-summary-mode-hook . hl-line-mode))

(use-package window
  :after (gnus-art)
  :defines (gnus-article-mode-map)

  :bind
  ( :map gnus-article-mode-map
    ;; Delete the Article window without exiting its Summary group.
    ("q" . delete-window)))



;;
;; Host Security (info "(emacs) Host Security")
;;

(use-package files
  :custom
  ;; Trust content beneath the user's home directory.
  (trusted-content '("~/")))



;;
;; Network Security (info "(emacs) Network Security")
;;

(use-package nsm
  :after (bs-ext)

  :custom
  ;; Store remembered network-security decisions as persistent state
  ;; instead of placing them under `user-emacs-directory'.
  (nsm-settings-file
   (bs-path bs-state-directory "network-security.eld")))



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
  ;; Add a display buffer rule to make `ghostel' buffers shown in a
  ;; side window at the bottom of the frame.
  (add-to-list 'display-buffer-alist
               '((derived-mode . ghostel-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.35)))

  :hook
  ;; Export environment variables so that programs launched from Let
  ;; `ghostel' uses Emacs as its editor.
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
    ;; Switch to a `ghostel' buffer associated with the current
    ;; directory.
    ("C-s" . ghostel-dwim-switch)

    ;; Reuse an idle `ghostel' session for the current directory or
    ;; create one.
    ("s" . ghostel-dwim)))

(use-package shell-maker
  :custom
  ;; Keep `shell-maker' state beneath the shared Emacs state directory
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

(use-package bs-ext
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
  :after (bs-hooks bs-lib)

  :custom
  ;; Store persistent data in our state directory.
  (save-place-file (bs-path bs-state-directory "place.el"))

  :hook
  ;; Persist and restore cursor positions across sessions.
  (bs-first-file-hook . save-place-mode))

(use-package startup
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
                                      "saves-"))

  :demand t
  :no-require t)



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

  :custom
  ;; Recognize host/user password-store paths when callers such as the
  ;; NNTP backend query by host before knowing the login name.
  (auth-source-pass-extra-query-keywords t)

  :init
  ;; Enable the password-store backend for any `auth-source' consumer,
  ;; even when `gnus' is never opened in the current Emacs session.
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

  ;; Share an adaptive protected side window with Codex IDE, leaving
  ;; slot zero available for the dedicated `agent-shell' sidebar.
  (agent-shell-display-action
   `((display-buffer-reuse-window
      ,#'(lambda (buffer alist)
           (let ((wide-p
                  (and (integerp split-width-threshold)
                       (>= (frame-width) split-width-threshold))))
             (display-buffer-in-side-window
              buffer
              (append
               `((preserve-size
                  . ,(if wide-p '(t . nil) '(nil . t)))
                 (side . ,(if wide-p 'right 'bottom))
                 (slot . 1)
                 ,(if wide-p
                      '(window-width . 0.5)
                    '(window-height . 0.35)))
               alist)))))
     (window-parameters . ((no-delete-other-windows . t)))))

  ;; Open agent shells directly at the prompt without the package
  ;; welcome text.
  (agent-shell-show-welcome-message nil)

  :config
  ;; Store `agent-shell' cache entries under `bs-cache-directory'
  ;; while preserving the package helper's component-based path
  ;; interface.
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
    ;; Toggle the `agent-shell' manager from the custom agent prefix
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
  ;; Enable `tramp' integration so agent shells can operate on remote
  ;; buffers and paths.
  (agent-shell-tramp-mode +1))

(use-package codex-ide-session
  :bind
  ( :map ctl-c-x-map
    ;; Start Codex IDE from the custom agent prefix map.
    ("c" . codex-ide)))

(use-package codex-ide
  :custom
  ;; Sit and relax, patiently waiting for the app-server thread to be
  ;; ready.
  (codex-ide-request-timeout 60)

  :init
  ;; Share the adaptive protected side window used by regular
  ;; `agent-shell' sessions, while retaining each conversation buffer
  ;; for later reuse.
  (add-to-list 'display-buffer-alist
               `((derived-mode . codex-ide-session-mode)
                 (display-buffer-reuse-window
                  ,#'(lambda (buffer alist)
                       (let ((wide-p
                              (and
                               (integerp split-width-threshold)
                               (>= (frame-width)
                                   split-width-threshold))))
                         (display-buffer-in-side-window
                          buffer
                          (append
                           `((preserve-size
                              . ,(if wide-p '(t . nil) '(nil . t)))
                             (side . ,(if wide-p 'right 'bottom))
                             (slot . 1)
                             ,(if wide-p
                                  '(window-width . 0.5)
                                '(window-height . 0.35)))
                           alist)))))
                 (window-parameters . ((no-delete-other-windows . t))))))

(use-package codex-ide
  :after (codex-ide-session)

  ;; Load the complete package entrypoint after the session module, so
  ;; approval and event-loop handlers are ready for the first session.
  :demand t)

(use-package codex-ide-session-mode
  :bind
  ( :map codex-ide-session-mode-map
    ;; Leave \\`C-c RET' unbound so prompt submission has a single
    ;; mnemonic binding in Codex sessions.
    ("C-c RET" . nil)))

(use-package codex-ide-transcript
  :defines (codex-ide-session-mode-map)

  :bind
  ( :map codex-ide-session-mode-map
    ;; Submit Codex prompts with the same key used by `shell-maker'
    ;; buffers.
    ("C-c C-c" . codex-ide-submit)))

(use-package codex-ide-transient
  :bind
  ( :map ctl-c-x-map
    ;; Open the Codex IDE menu from the custom agent prefix map.
    ("C-c" . codex-ide-menu)))

(use-package corfu
  :after (codex-ide-session-mode)

  :hook
  ;; Enable `corfu' in `codex-ide' sessions so automatic slash command
  ;; completion uses the popup frontend instead of `*Completions*'.
  (codex-ide-session-mode-hook . corfu-mode))

(use-package gptel
  :commands (gptel
             gptel-send)
  :defines (gptel-display-buffer-action
            gptel-mode-map
            markdown-ts-mode-hook)
  :functions (gptel--handle-wait@display-read-only-response
              gptel-fsm-info
              gptel-make-preset)

  :custom
  ;; Use `org-mode' for dedicated chats so conversations can use `org'
  ;; native structure without enabling branching context globally.
  (gptel-default-mode 'org-mode)

  ;; Keep backend, model, and request status visible above each chat.
  (gptel-use-header-line t)

  ;; Share an adaptive protected side window with regular
  ;; `agent-shell' and `codex-ide' sessions, leaving slot zero to
  ;; agent-shell-sidebar.
  (gptel-display-buffer-action
   `((display-buffer-reuse-window
      ,#'(lambda (buffer alist)
           (let ((wide-p
                  (and (integerp split-width-threshold)
                       (>= (frame-width) split-width-threshold))))
             (display-buffer-in-side-window
              buffer
              (append
               `((preserve-size
                  . ,(if wide-p '(t . nil) '(nil . t)))
                 (side . ,(if wide-p 'right 'bottom))
                 (slot . 1)
                 ,(if wide-p
                      '(window-width . 0.5)
                    '(window-height . 0.35)))
               alist)))))
     (body-function . select-window)
     (window-parameters . ((no-delete-other-windows . t)))))

  :config
  ;; Display fallback output as soon as a request from a read-only
  ;; target starts, rather than waiting for its first response chunk.
  (define-advice gptel--handle-wait
      (:around (original-function fsm) display-read-only-response)
    "Call ORIGINAL-FUNCTION with FSM, then display its response target."
    (prog1 (funcall original-function fsm)
      (let* ((info (gptel-fsm-info fsm))
             (position (plist-get info :position))
             (target
              (and (markerp position)
                   (marker-buffer position)))
             (callback (plist-get info :callback)))
        (when (and target
                   (memq callback
                         '(gptel--insert-response
                           gptel-curl--stream-insert-response))
                   (with-current-buffer target
                     (or buffer-read-only
                         (get-char-property position 'read-only))))
          (let* ((response
                  (get-buffer-create "*LLM response*"))
                 (clear-status
                  (or
                   (plist-get info :bs-gptel-clear-response-status)
                   (lambda (_info)
                     (when (buffer-live-p response)
                       (with-current-buffer response
                         (setq-local header-line-format nil)))))))
            (with-current-buffer response
              (visual-line-mode 1)
              (setq-local
               header-line-format
               (propertize " Waiting for LLM response..."
                           'face 'warning)))
            (unless (plist-get info :bs-gptel-clear-response-status)
              (plist-put info :bs-gptel-clear-response-status
                         clear-status)
              (plist-put
               info :post
               (cons clear-status (plist-get info :post))))
            (display-buffer
             response
             '((display-buffer-reuse-window
                display-buffer-pop-up-window)
               (reusable-frames . visible))))))))

  ;; Guide implementation and review without changing the selected
  ;; backend or model.
  (gptel-make-preset
   'coding
   :description "Write, modify, and review code."
   :system
   (concat
    "Act as a coding assistant. Provide correct, maintainable "
    "solutions, preserve existing conventions, and explain "
    "non-obvious trade-offs concisely. Respond in Simplified Chinese "
    "unless the user explicitly requests another language. Preserve "
    "code, identifiers, commands, paths, and quoted text exactly."))

  ;; Explain technical material while making assumptions and evidence
  ;; explicit.
  (gptel-make-preset
   'explain
   :description "Explain code or technical material clearly."
   :system
   (concat
    "Explain the provided code or technical material clearly. State "
    "assumptions, use the relevant context, and distinguish facts "
    "from inferences. Respond in Simplified Chinese unless the user "
    "explicitly requests another language. Preserve code, "
    "identifiers, commands, paths and technical terms where needed."))

  ;; Extract conclusions, facts, actions, and unresolved questions.
  (gptel-make-preset
   'summary
   :description
   "Summarize conclusions, facts, actions, and open questions."
   ;; Make prepared feed, mail, and news context the required user
   ;; input instead of folding it into the system instructions.
   :use-context 'user
   :system
   (concat
    "Summarize in Simplified Chinese unless the user "
    "explicitly requests another language. Extract the main "
    "conclusions, key facts, action items, and unresolved "
    "questions without adding unsupported claims. Preserve "
    "code, identifiers, paths, and quoted text exactly."))

  ;; Translate between Chinese and English while preserving structure.
  (gptel-make-preset
   'translate
   :description "Translate between Chinese and English."
   :system
   (concat
    "Translate between Chinese and English according to the "
    "source language. Preserve meaning, tone, structure, "
    "formatting, and code exactly unless asked otherwise."))

  :bind
  ( :map ctl-c-x-map
    ;; Create or switch to a dedicated `gptel' chat.
    ("g" . gptel)

    ;; Send the active region or buffer text from any buffer.
    ("RET" . gptel-send)

    :map gptel-mode-map
    ;; Submit prompts with the same mnemonic used by `agent-shell' and
    ;; `codex-ide'; a prefix argument opens the `gptel' menu.
    ("C-c C-c" . gptel-send)

    ;; Keep one unambiguous prompt-submission binding in `gptel'
    ;; chats.
    ("C-c RET" . nil))

  :hook
  ;; Render read-only fallback responses as Markdown without starting
  ;; the `grip-mode' preview normally enabled by
  ;; `markdown-ts-mode-hook'.
  (gptel-pre-response-hook
   . (lambda ()
       (when (string= (buffer-name) "*LLM response*")
         (setq-local header-line-format nil)
         (unless (eq major-mode 'markdown-ts-mode)
           (require 'markdown-ts-mode)
           (cl-letf (((symbol-value 'markdown-ts-mode-hook)
                      (remq #'grip-mode markdown-ts-mode-hook)))
             (markdown-ts-mode))))))

  ;; Distinguish model output from prompts without changing response
  ;; text or moving point while a response is streaming.
  (gptel-mode-hook . gptel-highlight-mode))

(use-package gptel-context
  :commands (gptel-add)
  :defines (bs-elfeed-context-buffer-name
            bs-gnus-context-buffer-name
            bs-mu4e-context-buffer-name
            gptel-context)

  :custom
  ;; Exclude ignored and other non-project files when a directory is
  ;; added recursively to the request context.
  (gptel-context-restrict-to-project-files t)

  :bind
  ( :map ctl-c-x-map
    ;; Add or remove the active region or buffer from `gptel' context.
    ("a" . gptel-add))

  :hook
  ;; Give only the originating feed, mail, or news buffer access to
  ;; the most recently prepared hidden context.
  ((bs-elfeed-search-context-hook
    bs-gnus-summary-thread-context-hook
    bs-mu4e-headers-thread-context-hook)
   .
   (lambda ()
     (require 'gptel-context)
     (when-let* ((context-name
                  (cond
                   ((derived-mode-p 'elfeed-search-mode
                                    'elfeed-tree-mode)
                    bs-elfeed-context-buffer-name)
                   ((derived-mode-p 'gnus-summary-mode
                                    'gnus-group-mode)
                    bs-gnus-context-buffer-name)
                   ((derived-mode-p 'mu4e-headers-mode
                                    'mu4e-main-mode)
                    bs-mu4e-context-buffer-name)))
                 (context (get-buffer context-name))
                 (source (current-buffer)))
       (dolist (buffer (buffer-list))
         (with-current-buffer buffer
           (when (local-variable-p 'gptel-context)
             (setq gptel-context
                   (delq context gptel-context)))))
       (with-current-buffer source
         (unless (local-variable-p 'gptel-context)
           (setq-local gptel-context
                       (copy-sequence gptel-context)))
         (cl-pushnew context gptel-context :test #'eq))))))

(use-package gptel-openai-oauth
  :after (bs-lib gptel)
  :defines (gptel--openai-oauth-token-file)

  :config
  ;; Keep the refresh token with other persistent Emacs state instead
  ;; of placing it below `user-emacs-directory'.
  (setq gptel--openai-oauth-token-file
        (bs-path bs-state-directory "gptel/openai-oauth-token"))

  :demand t)

(use-package gptel-org
  :custom
  ;; Keep conversations linear unless branching is enabled for a
  ;; specific workflow at run time.
  (gptel-org-branching-context nil))

(use-package gptel-request
  :after (gptel-openai-oauth)
  :functions (gptel-make-openai-oauth)

  :custom
  ;; Use ChatGPT subscription authentication with a balanced Codex
  ;; model as the initial selection.  Both remain adjustable at run
  ;; time through `gptel-menu'.
  (gptel-backend (gptel-make-openai-oauth "Codex"))
  (gptel-model 'gpt-5.6-terra)

  ;; Mark reasoning in the chat while excluding it from subsequent
  ;; conversation turns.
  (gptel-include-reasoning 'ignore)

  ;; Show model responses as they arrive without moving point to keep
  ;; editing and window navigation under explicit user control.
  (gptel-stream t)

  ;; Follow supported `org' links so chats can send linked text,
  ;; images, and other media to capable models.
  (gptel-track-media t)

  :demand t)

(use-package gptel-rewrite
  :commands (gptel-rewrite)

  :custom
  ;; Replace the selected region as soon as a rewrite succeeds.
  (gptel-rewrite-default-action 'accept)

  :bind
  ( :map ctl-c-x-map
    ;; Rewrite the active region with `gptel'.
    ("e" . gptel-rewrite)))

(use-package gptel-transient
  :commands (gptel-menu)
  :functions (transient-append-suffix
               transient-get-suffix)

  :config
  ;; Treat the GUI Return event like \\`RET' in the `gptel' transient.
  ;; `gnus' binds \\`<return>' directly, preventing its usual
  ;; translation to \\`RET' before `transient' sees it.
  (unless (ignore-errors
            (transient-get-suffix 'gptel-menu "<return>"))
    (transient-append-suffix
      'gptel-menu 'gptel--suffix-send
      '("<return>" gptel--suffix-send
        :description "" :format "")
      'always)))

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
  ;; Disable the default global binding from `openspec'; expose the
  ;; status command under the custom agent prefix map instead.
  (openspec-status-key nil)

  :config
  ;; Show `openspec' status buffers in a bottom side window so
  ;; reviewing proposals and tasks does not replace the current
  ;; editing window.
  (add-to-list 'display-buffer-alist
               '((derived-mode . openspec-mode)
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)))

  :bind
  ( :map ctl-c-x-map
    ;; Open the `openspec' project status from the custom agent prefix
    ;; map.
    ("o" . openspec-status)))

(use-package org
  :after (gptel)
  :defines (gptel-mode-map)

  :bind
  ( :map gptel-mode-map
    ;; Retain access to `org-ctrl-c-ctrl-c' after taking over its
    ;; usual binding for prompt submission.
    ("C-c C-M-c" . org-ctrl-c-ctrl-c)))

(use-package shell-maker
  :after (agent-shell)

  :bind
  ( :map agent-shell-mode-map
    ;; Submit the current `shell-maker' input without leaving insert
    ;; flow.
    ("C-c C-c" . shell-maker-submit)))

(use-package simple
  :after (agent-shell)

  :bind
  ( :map agent-shell-mode-map
    ;; Keep \\`RET' as a plain newline inside `agent-shell' buffers;
    ;; explicit submission remains on \\`C-c C-c'.
    ("RET" . newline)))



;;
;; Denote (info "(denote) Top")
;;

(use-package consult-denote
  :after (bs-hooks)

  :bind
  ( :map ctl-c-n-map
    ;; Search and select `denote' notes using `consult', providing
    ;; narrowing, preview, and live filtering over note filenames.
    ("f" . consult-denote-find)

    ;; Perform full-text search across `denote' notes using `consult'
    ;; as the front-end, enabling interactive narrowing of grep
    ;; results.
    ("g" . consult-denote-grep))

  :hook
  ;; Enable `consult-denote-mode' early after startup.  This activates
  ;; integration between `consult' and `denote', ensuring that
  ;; `consult'-based commands are aware of `denote' notes without
  ;; requiring manual activation per buffer.
  (bs-after-startup-late-hook . consult-denote-mode))

(use-package denote
  :after (bs-lib)
  :commands (denote-rename-buffer-mode)

  :custom
  ;; Use the `org' date reader when prompting for dates, enabling
  ;; calendar navigation and flexible date input.
  (denote-date-prompt-use-org-read-date t)

  ;; Set the root directory for `denote' notes.  All notes are stored
  ;; beneath this path.
  (denote-directory (bs-path* "~/org" "notes"))

  ;; Do not exclude any subdirectories under `denote-directory'.
  (denote-excluded-directories-regexp nil)

  ;; Infer keywords automatically from note content and context when
  ;; creating or renaming notes.
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

  ;; Do not automatically save buffers during `denote' operations.
  (denote-save-buffers nil)

  ;; Sort keywords alphabetically when writing them to front matter.
  (denote-sort-keywords t)

  :config
  ;; Enable automatic buffer renaming to keep buffer names in sync
  ;; with `denote' file names.
  (denote-rename-buffer-mode +1)

  :bind
  ( :map ctl-c-n-map
    ;; Insert links to existing `denote' notes, with interactive
    ;; selection and completion.
    ("L" . denote-add-links)

    ;; Rename the current note using its front matter as the source of
    ;; truth for title and keywords.
    ("R" . denote-rename-file-using-front-matter)

    ;; Display back-links for the current note, showing which notes
    ;; reference it.
    ("b" . denote-backlinks)

    ;; Open a `dired' buffer rooted at the `denote' notes directory.
    ("d" . denote-dired)

    ;; Insert a link to another `denote' note.
    ("l" . denote-link)

    ;; Create a new `denote' note.
    ("n" . denote)

    ;; Insert a link generated from a content-based `denote' query.
    ("q c" . denote-query-contents-link)

    ;; Insert a link generated from a filename-based `denote' query.
    ("q f" . denote-query-filenames-link)

    ;; Rename the current `denote' file interactively.
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
    ;; Rename marked `denote' files using their front matter.
    ("C-c C-d C-R"
     .
     denote-dired-rename-marked-files-using-front-matter)

    ;; Insert links to all marked `denote' notes.
    ("C-c C-d C-i" . denote-dired-link-marked-notes)

    ;; Rename marked `denote' files by modifying their keyword sets.
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)

    ;; Rename marked `denote' files interactively.
    ("C-c C-d C-r" . denote-dired-rename-files))

  :hook
  ;; Enable `denote-dired-mode' in `dired' buffers.  This augments
  ;; `dired' with `denote'-specific commands and metadata handling.
  (dired-mode-hook . denote-dired-mode))

(use-package denote-journal
  :after (denote)

  :custom
  ;; Reuse one journal entry per calendar day instead of creating a
  ;; separate entry on every invocation.
  (denote-journal-interval 'daily)

  ;; Mark every journal entry with `journal' so it can be identified
  ;; and retrieved independently of ordinary `denote' notes.
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
  ;; encrypted file without specifying recipients explicitly, these
  ;; keys will be used by default.
  (epa-file-select-keys 'silent))

(use-package epa-file
  :after (epa)
  :commands (epa-file-enable)

  :config
  ;; Silencing all messages during `epa-file-enable' executing.
  (advice-add 'epa-file-enable :around 'bs-silence-message)

  ;; Enable `epa-file' so that Emacs can automatically recognize and
  ;; transparently handle *.gpg files.  When opening an encrypted
  ;; file, it is automatically decrypted; when saving, it is
  ;; automatically encrypted again.
  (epa-file-enable))

(use-package epa-hook
  :custom
  ;; Set the default recipient(s) for file encryption.  When saving an
  ;; encrypted file without specifying recipients explicitly,
  ;; `user-mail-address' key will be used by default.
  (epa-file-encrypt-to `(,user-mail-address)))

(use-package epg-config
  :custom
  ;; Configure `epg-config' to use loop-back pinentry mode, so that
  ;; Emacs handles passphrase prompts internally instead of spawning
  ;; an external pinentry program.  This allows password input
  ;; directly in the mini-buffer.
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
;; mu4e (info "(mu4e) Top")
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

     ;; Atlassian bounce domains whose pre-organization label contains
     ;; "bounces".
     "\\`[^@]+@\\(?:[^@.]+\\.\\)*[^@.]*bounces[^@.]*\\.atlassian\\.[^@]+\\'"

     ;; Stripe's dedicated bounce domain.
     "\\`[^@]+@bounce\\.stripe\\.com\\'"

     ;; Linux Foundation encoded-recipient envelope addresses.
     "\\`[[:alnum:]]+-[^@=]+=.+@\\(?:[^@.]+\\.\\)+linuxfoundation\\.org\\'"

     ;; Mailing-list rewritten senders, preserving normal list posting
     ;; addresses without an equals sign.
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
  ;; Normalize the `mu4e' compose completion candidates so display
  ;; names stay readable and automated senders are hidden.
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
  :defines (mu4e-headers-mode-map)

  :init
  ;; Render header `:from' fields with cleaned contact display names
  ;; instead of exposing embedded email addresses in names.
  (bs-mu4e-headers-enable)

  :bind
  ( :map mu4e-headers-mode-map
    ;; Prepare today's local messages from the active account as LLM
    ;; context.
    ("C-c m t" . bs-mu4e-prepare-today-context)

    ;; Prepare the current message and its replies as LLM context.
    ("C-c m m" . bs-mu4e-headers-prepare-subthread-context)))

(use-package bs-mu4e
  :after (mu4e-view)
  :commands (bs-mu4e-view-xwidget-enable)

  :init
  ;; Open an HTML alternative in Xwidget when WebKit support is
  ;; available, both after initial rendering and after toggling from
  ;; plain text to HTML.
  (bs-mu4e-view-xwidget-enable))

(use-package bs-mu4e
  :after (mu4e-alert)
  :commands (bs-mu4e-notifications-enable)

  :custom
  ;; Persist sender avatars separately from other Mu4e state so they
  ;; can be expired without invalidating searches or contacts.
  (bs-mu4e-notifications-avatar-cache-directory
   (bs-path bs-cache-directory "mu4e/notification-avatars/"))

  ;; Refresh avatars after 90 days while retaining them across Emacs
  ;; sessions and notification checks.
  (bs-mu4e-notifications-avatar-cache-expiry (* 90 24 60 60))

  ;; Leave each actionable notification visible for fifteen seconds.
  (bs-mu4e-notifications-timeout (* 15 1000))

  ;; Open each notification Read action in a new frame belonging to
  ;; the current Emacs session.
  (bs-mu4e-notifications-read-display-function
   #'bs-call-in-new-frame)

  :config
  ;; Replace grouped `mu4e-alert' delivery with one actionable desktop
  ;; notification for each unread message.
  (bs-mu4e-notifications-enable))

(use-package consult-mu
  :functions (consult-mu--view-action)

  :custom
  ;; Use the async `mu4e'-backed search by default so selected
  ;; candidates keep the normal `mu4e' header and message actions.
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

  ;; Open the selected message in the regular `mu4e' view buffer
  ;; instead of using reply, forward, or a custom action as the
  ;; default.
  (consult-mu-action 'consult-mu--view-action)

  :bind
  ( :map goto-map
    ;; Put mail search under the standard `goto-map' prefix.
    ("m" . consult-mu)))

(use-package consult-mu-embark
  :after (embark consult-mu)

  :demand t)

(use-package corfu
  :after (mu4e-compose)

  :hook
  ;; Enable `corfu' in compose buffers so CAPF-based recipient
  ;; completion uses the configured popup UI.
  (mu4e-compose-mode-hook . corfu-mode))

(use-package gptel-transient
  :after (mu4e-headers)

  :bind
  ( :map mu4e-headers-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)))

(use-package gptel-transient
  :after (mu4e-main)
  :defines (mu4e-main-mode-map)

  :bind
  ( :map mu4e-main-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)))

(use-package mu4e
  :bind
  ( :map ctl-c-a-map
    ;; Open the `mu4e' mail interface from the custom application map.
    ("m" . mu4e)))

(use-package mu4e-alert
  :when (eq system-type 'gnu/linux)
  :after (mu4e)
  :commands (mu4e-alert-enable-notifications)
  :functions (mu4e-alert-set-default-style)

  :custom
  ;; Query individual messages so `bs-mu4e' can attach actions to the
  ;; exact message represented by each notification.
  (mu4e-alert-email-notification-types '(subjects))

  :config
  ;; Use the desktop notification backend for new-message alerts, then
  ;; enable notification delivery once the backend is selected.
  (mu4e-alert-set-default-style 'notifications)
  (mu4e-alert-enable-notifications)

  :demand t)

(use-package mu4e-compose
  :hook
  ;; Keep the major-mode label compact in `mu4e-compose' buffers.
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
  ;; Keep the major-mode label compact in `mu4e-headers' buffers.
  (mu4e-headers-mode-hook . (lambda ()
                              (setq-local mode-name "Mail"))))

(use-package mu4e-helpers
  :custom
  ;; Select the fancy side of mark pairs.  Every configured glyph
  ;; below is provided by most fonts, which keeps the header layout
  ;; strictly monospaced without font fallback.
  (mu4e-use-fancy-chars t)

  ;; Route `mu4e-read-option' through the configured completion
  ;; function instead of the built-in `mu4e' option reader.
  (mu4e-read-option-use-builtin nil)

  ;; Use the standard completion entry point so the active minibuffer
  ;; completion UI handles the `mu4e' option prompts.
  (mu4e-completing-read-function 'completing-read))

(use-package mu4e-main
  :config
  (add-to-list 'display-buffer-alist
               '("\\*mu4e-main\\*"
                 (display-buffer-same-window)))

  :hook
  ;; Keep the major-mode label compact in `mu4e-main' and info
  ;; buffers.
  ((mu4e-main-mode-hook mu4e-org-mode-hook)
   .
   (lambda ()
     (setq-local mode-name "Mail"))))

(use-package bs-mu4e
  :after (mu4e-main)
  :commands (bs-mu4e-main-enable
             bs-mu4e-prepare-today-context)
  :defines (mu4e-main-mode-map)

  :init
  ;; Present the main mail dashboard with the same visual hierarchy,
  ;; aligned counts, and context-aware status used by Gnus and Elfeed.
  (bs-mu4e-main-enable)

  :bind
  ( :map mu4e-main-mode-map
    ;; Prepare today's local messages from the active account as LLM
    ;; context.
    ("C-c m t" . bs-mu4e-prepare-today-context)))

(use-package mu4e-modeline
  :custom
  ;; Disable the global `mu4e' modeline indicators while keeping
  ;; buffer-specific `mu4e' modeline information available.
  (mu4e-modeline-show-global nil))

(use-package mu4e-org
  :hook
  ;; Keep the major-mode label compact in `mu4e-org' link buffers.
  (mu4e-org-agenda-links-mode-hook
   .
   (lambda ()
     (setq-local mode-name "Mail"))))

(use-package mu4e-search
  :custom
  ;; Return complete search results so inbox threads retain related
  ;; sent replies after the number of direct matches exceeds the
  ;; `mu4e' default result limit.
  (mu4e-search-full t))

(use-package mu4e-thread
  :bind
  ( :map mu4e-thread-mode-map
    ;; Leave \\`C-<tab>' available outside `mu4e-thread' by removing
    ;; this mode-specific binding.
    ("C-<tab>" . nil)))

(use-package mu4e-update
  :custom
  ;; Hide the annoying "mu4e Retrieving mail..." message in the
  ;; minibuffer.
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
  ;; Keep the major-mode label compact in `mu4e-update' buffers.
  (mu4e--update-mail-mode-hook . (lambda ()
                                   (setq-local mode-name "Mail"))))

(use-package mu4e-view
  ;; Declare the `gnus' MIME preference used below without loading its
  ;; implementation during initialization.
  :defines (mm-discouraged-alternatives)

  :hook
  ;; Prefer a usable plain-text alternative in `mu4e-view', while
  ;; retaining HTML as the fallback when plain text is absent or
  ;; empty.
  (mu4e-view-mode-hook
   .
   (lambda ()
     (setq-local mm-discouraged-alternatives '("text/html"))))

  ;; Keep the major-mode label compact in rendered and raw mail views.
  ((mu4e-raw-view-mode-hook mu4e-view-mode-hook)
   .
   (lambda ()
     (setq-local mode-name "Mail"))))

(use-package simple
  :custom
  ;; Route generic Emacs mail entry points, such as `compose-mail', to
  ;; the `mu4e' compose interface.
  (mail-user-agent 'mu4e-user-agent))



;;
;; Org (info "(org) Top")
;;

(use-package ol
  :custom
  ;; Display links using their description text instead of their raw
  ;; `org' syntax.
  (org-link-descriptive t))

(use-package org
  :after (bs-lib)
  :commands (org-set-tags-command)

  :custom
  ;; Directory beneath `org' files.
  (org-directory (bs-path* "~/org"))

  ;; Restrict agenda discovery to the GTD subtree so agenda commands
  ;; operate on the curated task set instead of every `org' file under
  ;; `org-directory'.
  (org-agenda-files (list (bs-path* org-directory "gtd/")
                          (bs-path org-directory "calendar.org")))

  ;; Set the string displayed at folded outline boundaries.  Setting
  ;; this to nil disables the display of a custom ellipsis and lets
  ;; `org' fallback to the default three dots.
  (org-ellipsis nil)

  ;; Enable direct TODO state selection for \\`C-c C-t' when shortcut
  ;; keys are defined, and present the available states only in the
  ;; prompt instead of opening the temporary selection window.
  (org-use-fast-todo-selection 'expert)

  ;; Hide the surrounding markup characters for bold, italic,
  ;; verbatim, and similar constructs (e.g. *bold* → bold).  This
  ;; affects only the on-screen representation; the underlying `org'
  ;; syntax remains unchanged in the buffer.
  (org-hide-emphasis-markers t)

  ;; Render LaTeX-like entities using their unicode equivalents when
  ;; possible, such as Greek letters, math symbols, and arrows.
  (org-pretty-entities t)

  ;; Enable indentation-based virtual structure when opening `org'
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
  ;; Enable `org-appear-mode' whenever entering `org-mode'.  This mode
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
  ;; Enable `org-edna' in `org' buffers so TODO-state dependencies and
  ;; trigger properties are enforced when tasks change state.
  (org-mode-hook . (lambda ()
                     (org-edna-mode +1))))

(use-package org-gtd
  :preface
  ;; Acknowledge the required `org-gtd' 4.x upgrade steps up front so
  ;; the package does not emit its one-time migration warning on load.
  (setq org-gtd-update-ack "4.0.0"))

(use-package org-gtd-agenda-transient
  :after (org-agenda)

  :bind
  ( :map org-agenda-mode-map
    ;; Open the `org-gtd' action menu for the agenda item at point,
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
  ;; the registered event template available through `org-gtd'
  ;; capture.
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
    ;; Open the central `org-gtd' menu for capture, engagement, system
    ;; review, reflection, and archival commands.
    ("g" . org-gtd-command-center)))

(use-package org-gtd-core
  :custom
  ;; Store the `org-gtd' inbox, archive, and supporting files inside
  ;; the GTD subtree already included in `org-agenda-files'.
  (org-gtd-directory (bs-path* org-directory "gtd/"))

  ;; Bind the `org-gtd' semantic states to the workflow keywords
  ;; defined above so capture and processing commands follow the same
  ;; naming, including the local `CNCL' spelling for canceled tasks.
  (org-gtd-keyword-mapping '((todo . "TODO")
                             (next . "NEXT")
                             (wait . "WAIT")
                             (done . "DONE")
                             (canceled . "CNCL"))))

(use-package org-gtd-engage
  :after (bs-ext)

  :bind
  ( :map ctl-c-a-map
    ;; Open the `org-gtd' agenda view focused on actionable work and
    ;; other GTD-specific reviews.
    ("a" . org-gtd-engage)))

(use-package org-gtd-mode
  :after (bs-hooks)

  :hook
  ;; Enable global `org-gtd' integration shortly after startup,
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
  :functions (org-gtd-organize-type-member-p)

  :custom
  ;; Replace the package default, which prompts for tags on every
  ;; item, with type-aware context and Area of Focus metadata hooks.
  (org-gtd-organize-hooks
   (list
    (lambda ()
      (when (org-gtd-organize-type-member-p
             '(next-action calendar habit project-task))
        (org-set-tags-command)))
    #'org-gtd-set-area-of-focus)))

(use-package org-gtd-process
  :after (bs-ext)

  :bind
  ( :map ctl-c-a-map
    ;; Process inbox items sequentially through the `org-gtd' clarify
    ;; workflow until the configured inbox files are exhausted.
    ("i" . org-gtd-process-inbox)))

(use-package org-gtd-wip
  :after (org-gtd-mode)

  :demand t)

(use-package org-id
  :custom
  ;; Keep `org-id' location cache next to the configured `org' files
  ;; instead of using the default file in the user Emacs directory.
  (org-id-locations-file (bs-path org-directory ".id-locations")))

(use-package org-modern
  :after (org)

  :hook
  ;; Activate `org-modern-mode' when entering `org-mode'.  This
  ;; adjusts the visual presentation of headings, lists, blocks, and
  ;; tags to provide a cleaner and more consistent UI layer.
  (org-mode-hook . org-modern-mode))

(use-package org-modern
  :after (org-agenda)

  :hook
  ;; Enable modern rendering for `org-agenda' buffers.  The hook runs
  ;; after the agenda is fully generated, ensuring that all agenda
  ;; lines are replaced with their modern visual counterparts.
  (org-agenda-finalize-hook . org-modern-agenda))

(use-package org-modern-indent
  :after (org)

  :hook
  ;; Add indentation support for `org-modern', aligning visual
  ;; elements with the structural indentation defined by `org'.  This
  ;; improves readability without altering underlying `org' syntax.
  (org-mode-hook . org-modern-indent-mode))



;;
;; Transparent Remote (file) Access (info "(tramp) Top")
;;

(use-package tramp
  :after (bs-lib)

  :custom
  ;; Automatically save remote files to our local directory, of course
  ;; using our data directory.
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
  ;; Centralizing the storage of `transient' data files to a directory
  ;; under `bs-state-directory'.
  (transient-history-file (bs-path bs-state-directory
                                   "transient"
                                   "history.el"))
  (transient-levels-file  (bs-path bs-state-directory
                                   "transient"
                                   "levels.el"))
  (transient-values-file  (bs-path bs-state-directory
                                   "transient"
                                   "values.el")))



;;
;; Web Feed Reader
;;

(use-package gptel-transient
  :after (elfeed-search)
  :defines (elfeed-search-mode-map)

  :bind
  ( :map elfeed-search-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)))

(use-package bs-elfeed
  :after (elfeed-search)
  :commands (bs-elfeed-search-disable
             bs-elfeed-search-enable
             bs-elfeed-search-prepare-context
             bs-elfeed-prepare-today-context
             bs-elfeed-notifications-disable
             bs-elfeed-notifications-enable
             bs-elfeed-tree-disable
             bs-elfeed-tree-enable)
  :defines (elfeed-search-mode-map)

  :custom
  ;; Reuse site favicons for desktop notifications for three months.
  (bs-elfeed-notifications-favicon-cache-directory
   (bs-path bs-cache-directory
            "elfeed/notification-favicons/"))
  (bs-elfeed-notifications-favicon-cache-expiry (* 90 24 60 60))

  ;; Leave each actionable notification visible for fifteen seconds.
  (bs-elfeed-notifications-timeout (* 15 1000))

  ;; Open each notification Read action in a new frame belonging to
  ;; the current Emacs session.
  (bs-elfeed-notifications-read-display-function
   #'bs-call-in-new-frame)

  ;; Check all subscribed feeds every five minutes.
  (bs-elfeed-update-interval (* 5 60))

  :bind
  ( :map elfeed-search-mode-map
    ;; Prepare today's locally stored entries as LLM context.
    ("C-c m t" . bs-elfeed-prepare-today-context)))

(use-package elfeed
  :after (bs-lib)
  :commands (elfeed)
  :defines (elfeed-db-directory
            elfeed-entry-point
            elfeed-search-filter
            elfeed-search-mode-map
            elfeed-search-remain-on-entry
            elfeed-search-sort-function
            elfeed-show-entry-switch)
  :functions (elfeed-db-save
              elfeed-queue-count-total
              elfeed-search-entries
              elfeed-search-show-entry
              elfeed-tree-update
              elfeed-untag
              elfeed-update)

  :custom
  ;; Enter through the tag and feed hierarchy instead of opening an
  ;; undifferentiated search immediately.
  (elfeed-entry-point 'elfeed-tree)

  :config
  ;; After the first complete update, treat the imported backlog as
  ;; read and record that this one-time migration has finished.
  (add-hook
   'elfeed-update-hook
   (lambda (_url)
     (let ((complete
            (bs-path elfeed-db-directory
                     "initial-update-complete")))
       (when (and (not (file-exists-p complete))
                  (zerop (elfeed-queue-count-total)))
         (let ((unread (elfeed-search-entries "+unread")))
           (when unread
             (elfeed-untag unread 'unread)))
         (elfeed-db-save)
         (with-temp-file complete)
         (elfeed-tree-update :force)))))

  ;; Follow Search movement only when an article window already
  ;; exists; simple navigation never creates that window on its own.
  (keymap-set
   elfeed-search-mode-map "n"
   (lambda (count)
     "Move COUNT entries forward and follow a visible article."
     (interactive "p")
     (forward-line count)
     (when (get-buffer-window "*elfeed-entry*")
       (call-interactively #'elfeed-search-show-entry))))
  (keymap-set
   elfeed-search-mode-map "p"
   (lambda (count)
     "Move COUNT entries backward and follow a visible article."
     (interactive "p")
     (forward-line (- count))
     (when (get-buffer-window "*elfeed-entry*")
       (call-interactively #'elfeed-search-show-entry))))

  :bind
  ( :map ctl-c-a-map
    ;; Open the Elfeed tag and feed hierarchy from the custom
    ;; application map.
    ("f" . elfeed)))

(use-package elfeed-db
  :after (bs-lib)

  :custom
  ;; Keep feed contents, metadata, and related state below the shared
  ;; Emacs data directory.
  (elfeed-db-directory (bs-path bs-data-directory "elfeed/")))

(use-package elfeed-link
  :after (elfeed ol)

  :demand t)

(use-package elfeed-org
  :after (elfeed)
  :functions (elfeed-org)

  :custom
  ;; Maintain subscriptions and inherited tags in a dedicated `org'
  ;; file outside `org-agenda-files'.
  (rmh-elfeed-org-files '("~/org/feeds.org"))

  :config
  (elfeed-org)

  :demand t)

(use-package elfeed-score
  :after (elfeed)
  :defines (elfeed-score-map)
  :functions (elfeed-score-enable)

  :config
  ;; Enable automatic scoring without replacing chronological sorting,
  ;; then install the renderer and notifications after all new-entry
  ;; taggers are active.
  (elfeed-score-enable t)
  (bs-elfeed-search-enable)
  (bs-elfeed-notifications-enable)
  (keymap-set elfeed-search-mode-map "=" elfeed-score-map)

  :demand t)

(use-package elfeed-score-rule-stats
  :after (elfeed-score)

  :custom
  ;; Persist rule hit statistics separately from the rules themselves.
  (elfeed-score-rule-stats-file
   (bs-path elfeed-db-directory "score-stats.el")))

(use-package elfeed-score-serde
  :after (elfeed-score)

  :custom
  ;; Store editable scoring rules beside the `elfeed' database.
  (elfeed-score-serde-score-file
   (bs-path elfeed-db-directory "score.el")))

(use-package elfeed-search
  :custom
  ;; Show unread entries by default without imposing a time cutoff.
  (elfeed-search-filter "+unread")

  ;; Cycle with \\`o' between reverse chronological and score order,
  ;; retaining time order as the initial view.
  (elfeed-search-sort-function '(nil elfeed-score-sort))

  ;; Keep point on the entry displayed in the adjacent article window.
  (elfeed-search-remain-on-entry '(show))

  :bind
  ( :map elfeed-search-mode-map
    ;; Prepare entries selected by native marks, the active region, or
    ;; point as LLM context.  Plain `m' remains the native mark command.
    ("C-c m m" . bs-elfeed-search-prepare-context)))

(use-package elfeed-show
  :custom
  ;; Display articles in another window while retaining focus in the
  ;; Search buffer for continuous navigation.
  (elfeed-show-entry-switch
   (lambda (buffer)
     (display-buffer
      buffer
      '((display-buffer-reuse-window
         display-buffer-pop-up-window))))))

(use-package elfeed-tree
  :after (elfeed)

  :bind
  ( :map elfeed-tree-mode-map
    ;; Open the `gptel' send menu for the prepared context.
    ("C-c m g" . gptel-menu)

    ;; Prepare today's locally stored entries as LLM context.
    ("C-c m t" . bs-elfeed-prepare-today-context))

  :custom
  ;; Build tree counts and searches from unread entries, matching the
  ;; default Search filter.
  (elfeed-tree-filter "+unread")

  :config
  ;; Render one synthetic, fully expanded tag hierarchy with the same
  ;; visual hierarchy as the Gnus Group/Topic buffer.
  (bs-elfeed-tree-enable))

(use-package elfeed-webkit
  :if (featurep 'xwidget-internal)
  :after (elfeed-show)
  :defines (elfeed-show-mode-map)
  :functions (elfeed-webkit-enable)

  :config
  ;; Prefer embedded WebKit rendering when this Emacs has xwidget
  ;; support; the ordinary SHR renderer remains the fallback
  ;; otherwise.
  (elfeed-webkit-enable)

  :bind
  ( :map elfeed-show-mode-map
    ;; Toggle an individual reading session between WebKit and `shr'.
    ("%" . elfeed-webkit-toggle))

  :demand t)

;;; init.el ends here
;; Local Variables:
;; fill-column: 70
;; indent-tabs-mode: nil
;; sentence-end-double-space: t
;; tab-width: 2
;; End:
