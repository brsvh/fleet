;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  .
  ((sentence-end-double-space . t)

   ;; Treat project-specific terminology as first-class vocabulary so
   ;; spell checking focuses on genuine mistakes rather than
   ;; repeatedly flagging domain terms.
   (jinx-dir-local-words . "config dev devShells devshells dirToAttrs
 direnv editorconfig emacs gitignore infix lefthook lf mkdir nixfmt
nixpkgs pipefail rebase toml treefmt untracked utf yaml yml")))

 (nix-mode
  .
  ;; Enforce a narrow, consistent formatting style for Nix code in
  ;; this project, keeping expressions compact and visually uniform.
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50")))))

 (nix-ts-mode
  .
  ;; Apply the same formatting constraints to Tree-sitter-based Nix
  ;; buffers, ensuring consistency regardless of the active major
  ;; mode.
  ((apheleia-formatters . ((nixfmt "nixfmt" "--width" "50"))))))
