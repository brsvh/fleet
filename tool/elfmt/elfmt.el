#!/usr/bin/env -S emacs --quick --script
;;; elfmt.el --- Format Emacs Lisp files  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Bingshan Chang <chang@bingshan.org>

;; Author: Bingshan Chang <chang@bingshan.org>
;; Keywords: lisp, tools
;; Package-Requires: ((emacs "30.1"))
;; Version: 0.1.0

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

;; Format Emacs Lisp and Lisp data files in place.
;;
;; Run this file directly, passing one or more files:
;;
;;   elfmt.el FILE...

;;; Code:

(require 'cl-lib)
(require 'editorconfig)
(require 'editorconfig-tools nil t)
(require 'macroexp)

(define-error 'elfmt-error "Emacs Lisp formatting error")

(defun elfmt--signal (format-string &rest args)
  "Signal an `elfmt-error' described by FORMAT-STRING and ARGS."
  (signal 'elfmt-error
          (list (apply #'format format-string args))))

(defun elfmt--print-error (message)
  "Print error MESSAGE to standard error."
  (princ (format "elfmt: %s\n" message)
         'external-debugging-output))

(defun elfmt--script-invocation-p ()
  "Return non-nil when this file is the active `--script' target."
  (let ((script-args
         (or (member "-scriptload" command-line-args)
             (member "--script" command-line-args))))
    (and (cadr script-args)
         (stringp load-file-name)
         (file-equal-p load-file-name (cadr script-args)))))

(defun elfmt--command-line-files ()
  "Return file names passed after the script on the command line."
  (if (equal (car command-line-args-left) "--")
      (cdr command-line-args-left)
    command-line-args-left))

(defun elfmt--validate-files (files)
  "Validate FILES before formatting and return them."
  (unless files
    (elfmt--signal "expected at least one file argument"))
  (dolist (file files)
    (unless (file-regular-p file)
      (elfmt--signal "%s is not a regular file" file)))
  files)

(defun elfmt--configure-editorconfig ()
  "Configure EditorConfig integration for noninteractive formatting."
  (unless (assq 'lisp-data-mode editorconfig-indentation-alist)
    (push '(lisp-data-mode . editorconfig--get-indentation-lisp-mode)
          editorconfig-indentation-alist))
  (when (boundp 'editorconfig-override-dir-local-variables)
    (setq editorconfig-override-dir-local-variables nil))
  (when (boundp 'editorconfig-override-file-local-variables)
    (setq editorconfig-override-file-local-variables nil)))

(defun elfmt--apply-editorconfig ()
  "Apply EditorConfig properties to the current buffer."
  (when buffer-file-name
    (let ((properties
           (editorconfig-call-get-properties-function
            buffer-file-name)))
      (condition-case err
          (run-hook-with-args 'editorconfig-hack-properties-functions
                              properties)
        (error
         (display-warning
          'elfmt
          (format "EditorConfig property hook failed: %S" err)
          :warning)))
      (editorconfig-set-coding-system-revert
       (gethash 'end_of_line properties)
       (gethash 'charset properties))
      (setq editorconfig-properties-hash properties)
      (editorconfig-set-local-variables properties)
      (condition-case err
          (run-hook-with-args 'editorconfig-after-apply-functions
                              properties)
        (error
         (display-warning
          'elfmt
          (format "EditorConfig after-apply hook failed: %S" err)
          :warning))))))

(defun elfmt--check-mode (file)
  "Ensure the current buffer uses a mode supported for FILE."
  (unless (derived-mode-p 'emacs-lisp-mode 'lisp-data-mode)
    (elfmt--signal "%s is not a supported Lisp file (major mode: %S)"
                   file major-mode)))

(defun elfmt--definition-indent-spec (form)
  "Return a safe indentation declaration from definition FORM."
  (when (and (memq (car-safe form)
                   '(cl-defmacro cl-defsubst cl-defun
                      defmacro defsubst defun))
             (symbolp (nth 1 form)))
    (let ((declarations
           (car (macroexp-parse-body (nthcdr 3 form))))
          indent-spec)
      (dolist (declaration declarations)
        (when (eq (car-safe declaration) 'declare)
          (let ((indent (assq 'indent (cdr declaration))))
            (when (and (consp (cdr indent))
                       (null (cddr indent))
                       (or (integerp (cadr indent))
                           (eq (cadr indent) 'defun)))
              (setq indent-spec (cadr indent))))))
      (when indent-spec
        (cons (nth 1 form) indent-spec)))))

(defun elfmt--collect-indent-specs ()
  "Collect safe indentation declarations from the current buffer."
  (when (derived-mode-p 'emacs-lisp-mode)
    (save-excursion
      (goto-char (point-min))
      (let ((read-circle nil)
            (read-symbol-shorthands nil)
            indent-specs)
        (condition-case nil
            (while t
              (let* ((form (read (current-buffer)))
                     (indent-spec
                      (ignore-errors
                        (elfmt--definition-indent-spec form))))
                (when indent-spec
                  (setq indent-specs
                        (cons indent-spec
                              (assq-delete-all (car indent-spec)
                                               indent-specs))))))
          (end-of-file nil)
          (error nil))
        indent-specs))))

(defun elfmt--install-indent-specs ()
  "Install indentation declarations and return prior values."
  (let (saved-properties)
    (dolist (indent-spec (elfmt--collect-indent-specs))
      (let ((symbol (car indent-spec)))
        (push (list symbol
                    (plist-member (symbol-plist symbol)
                                  'lisp-indent-function)
                    (get symbol 'lisp-indent-function))
              saved-properties)
        (put symbol 'lisp-indent-function (cdr indent-spec))))
    saved-properties))

(defun elfmt--restore-indent-specs (saved-properties)
  "Restore indentation properties from SAVED-PROPERTIES."
  (dolist (saved-property saved-properties)
    (let ((symbol (nth 0 saved-property)))
      (if (nth 1 saved-property)
          (put symbol
               'lisp-indent-function
               (nth 2 saved-property))
        (cl-remprop symbol 'lisp-indent-function)))))

(defun elfmt--normalize-indentation ()
  "Normalize leading whitespace for the applied EditorConfig style."
  (let ((normalizer
         (pcase (gethash 'indent_style editorconfig-properties-hash)
           ("space" #'untabify)
           ("tab" #'tabify))))
    (when normalizer
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (unless (nth 3 (syntax-ppss))
            (let ((start (point)))
              (back-to-indentation)
              (funcall normalizer start (point))))
          (forward-line 1))))))

(defun elfmt--indent-buffer ()
  "Indent the current buffer using declarations from its source."
  (let ((saved-properties (elfmt--install-indent-specs)))
    (unwind-protect
        (cl-letf (((symbol-function 'make-progress-reporter)
                   (lambda (&rest _) nil))
                  ((symbol-function 'progress-reporter-update)
                   (lambda (&rest _) nil))
                  ((symbol-function 'progress-reporter-done)
                   (lambda (&rest _) nil)))
          (indent-region (point-min) (point-max))
          (elfmt--normalize-indentation))
      (elfmt--restore-indent-specs saved-properties))))

(defun elfmt--format-file (file)
  "Format the Emacs Lisp FILE in place."
  (let ((buffer nil)
        (file-name (expand-file-name file)))
    (condition-case err
        (unwind-protect
            (progn
              (message "format %s" file-name)
              (let ((inhibit-message t)
                    (message-log-max nil))
                (setq buffer (find-file-noselect file-name)))
              (with-current-buffer buffer
                (elfmt--check-mode file-name)
                (elfmt--apply-editorconfig)
                (elfmt--indent-buffer)
                (save-buffer)))
          (when (buffer-live-p buffer)
            (kill-buffer buffer)))
      (elfmt-error (signal (car err) (cdr err)))
      (error
       (elfmt--signal "failed to format %s: %s"
                      file-name (error-message-string err))))))

(defun elfmt--run (files)
  "Format FILES in a process-local, noninteractive environment."
  (let ((auto-save-default nil)
        (backup-inhibited t)
        (before-save-hook nil)
        (create-lockfiles nil)
        (enable-local-eval nil)
        (enable-local-variables :safe)
        (make-backup-files nil)
        (save-silently t)
        (vc-follow-symlinks t))
    (elfmt--configure-editorconfig)
    (mapc #'elfmt--format-file (elfmt--validate-files files))))

(defun elfmt--main ()
  "Run the command-line formatter and return its process exit status."
  (condition-case err
      (progn
        (elfmt--run (elfmt--command-line-files))
        0)
    (elfmt-error (elfmt--print-error (cadr err)) 1)
    (error (elfmt--print-error (error-message-string err)) 1)))

(when (elfmt--script-invocation-p)
  (kill-emacs (elfmt--main)))

(provide 'elfmt)
;;; elfmt.el ends here
