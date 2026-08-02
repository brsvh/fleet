# Emacs configuration rules

These rules apply to `init.el` and `early-init.el`. Preserve each file's
existing organization and style when making changes.

## Sections and `use-package`

- A section starts after a form-feed character and has this shape:

  ```elisp
  

  ;;
  ;; Section title
  ;;
  ```

- Sort top-level `use-package` forms alphabetically by feature within each
  section. Keep forms for the same feature in their existing relative order.

- Pseudo features are allowed when they accurately identify the built-in owner
  of configuration, bindings, or hooks.

- Order `use-package` keywords as follows:

  01. `:when`, `:unless`, or `:if`
  02. `:after`
  03. `:commands`
  04. `:defines`
  05. `:functions`
  06. `:custom`
  07. `:preface`
  08. `:init`
  09. `:config`
  10. `:bind`
  11. `:bind-keymap`
  12. `:mode`
  13. `:hook`
  14. `:defer` or `:demand`
  15. `:no-require`

- Separate `:custom`, `:preface`, `:init`, `:config`, `:bind`, `:bind-keymap`,
  `:mode`, `:hook`, and `:defer`/`:demand` groups from the preceding group with
  one blank line. Do not insert a blank line before the first keyword in a form.

- Keep `:mode` and a directly following `:hook` adjacent. Keep `:no-require`
  immediately after `:defer` or `:demand`.

- A variable in `:custom` must be defined by the declared feature.

- A command in `:bind` must be defined by the declared feature.

- A named command in `:hook` must be defined by the declared feature. Commands
  referenced by `:bind` or `:hook` need not also appear in `:commands`.

## Comments and docstrings

- Use `fill-column` 70. Run `fill-paragraph` on every multiline prose comment
  after editing it. Do not fill or otherwise rewrite section comments.

- Quote feature names and other Lisp identifiers using the Emacs convention. Use
  the actual lowercase feature name instead of a display name:

  ```elisp
  ;; Enable `eglot' in programming buffers.
  ```

- Write key descriptions in comments using the escaped Emacs convention. For
  example:

  ```elisp
  ;; Press \\`C-c c j' to jump to the definition.
  ```

- Keep every `gptel` preset's explanatory comment with that preset.

- Fill each `:system` prompt to lines no longer than 70 columns while keeping
  lines reasonably close to that limit.

## Validation

- Run `treefmt` after modifying either Emacs initialization file.
- Run `check-parens`, `git diff --check`, and byte compilation after structural
  changes.
- Before replacing a live Emacs buffer, verify that it has no unsaved changes.
