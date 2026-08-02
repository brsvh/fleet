;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)))

 (lisp-data-mode
  .
  ((eval
    .
    (progn
      (setq-local apheleia-formatters
                  (copy-tree apheleia-formatters))
      (setf (alist-get 'elisp-format apheleia-formatters)
            '("elisp-format" inplace))
      (setq-local apheleia-formatter 'elisp-format)))))

 (markdown-ts-mode
  .
  ((eval
    .
    (progn
      (setq-local apheleia-formatters
                  (copy-tree apheleia-formatters))
      (setf (alist-get 'mdformat apheleia-formatters)
            '("mdformat"
              "--wrap" "80"
              "--extensions" "frontmatter"
              "-"))
      (setq-local apheleia-formatter 'mdformat)))))

 (nix-mode
  .
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50")))))

 (nix-ts-mode
  .
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50"))))))
