---
name: emacs-lisp-coding
description: >-
  Write, review, and refactor idiomatic Emacs Lisp following community style
  conventions. Use when working with Emacs configuration, .el packages or
  libraries, interactive commands, macros, custom variables or faces,
  autoloads, hooks, keymaps, major modes, minor modes, byte-compilation
  issues, checkdoc cleanup, package templates, or Emacs Lisp tests.
---

# Emacs Lisp Coding

Use this skill to produce maintainable Emacs Lisp that is ready for
byte-compilation and natural for Emacs users to customize.

## Workflow

1. Identify the code's role first: personal configuration, reusable library,
   package, major mode, minor mode, macro helper, test, or one-off migration.
1. Inspect neighboring `.el` files for the package prefix, minimum Emacs
   version, dependency style, test framework, and local conventions.
1. Keep changes scoped. Preserve existing public APIs, customization names,
   autoloads, keymaps, hooks, and feature names unless the user asks for a
   breaking change.
1. Load only the relevant bundled resource:
   - `references/emacs-lisp-quick-reference.md`: quick lookup for syntax,
     naming, interactive specs, hooks, keybindings, modes, macros, and common
     idioms.
   - `references/package-template.el`: package or reusable library skeletons.
   - `references/library-functions.el`: small helper functions, list/string/file
     helpers, macros, and interactive utilities.
   - `references/major-mode.el`: derived major modes, syntax tables, font-lock,
     indentation, imenu, eldoc, and mode registration.
   - `references/minor-mode.el`: buffer-local minor modes, globalized minor
     modes, overlays, hooks, timers, and mode maps.
1. Adapt examples by renaming every placeholder symbol, feature, group, face,
   URL, package header, and footer. Do not paste examples verbatim into a real
   package.
1. Validate with the narrowest useful command before finishing. Prefer existing
   project test commands when present; otherwise byte-compile changed files.

## Core Rules

- Enable lexical binding in new `.el` files:
  `;;; package.el --- Summary  -*- lexical-binding: t; -*-`.
- Keep conventional file structure for packages: header, `;;; Commentary:`,
  `;;; Code:`, explicit `require` forms, definitions, `(provide 'feature)`, and
  `;;; package.el ends here`.
- Prefix public symbols with the package or feature name. Prefix private helpers
  with `package--`. Keep face names, groups, variables, functions, commands,
  keymaps, hooks, and tests in the same namespace.
- Use `defgroup` and `defcustom` for user-facing options. Always include useful
  `:type` and `:group`; add `:safe` when a value can safely appear in file-local
  variables.
- Use `defvar-local` for buffer-local state. Avoid global mutable state unless
  it is part of the package design.
- Use spaces, standard Emacs indentation, one blank line between unrelated
  top-level forms, and closing parentheses on the final expression line.
- Prefer `when`, `unless`, `cond`, `pcase`, `dolist`, `dotimes`, and `seq-*`
  functions over verbose low-level control flow.
- Use function quotes for function values: `#'function-name`. Do not hard-quote
  lambdas.
- Use named functions for hooks, timers, advice, mode setup, and long-lived
  callbacks. Reserve inline lambdas for local one-off transformations.
- Use `require` for compile-time references. Add `(require 'cl-lib)`,
  `(require 'seq)`, or `(require 'subr-x)` when using their APIs.
- For optional package integrations, use `with-eval-after-load` and
  `declare-function` for externally defined functions that byte compilation
  cannot otherwise see.
- Add autoload cookies only to user-facing commands, mode definitions, and
  public entry points that should load on demand. Do not autoload private
  helpers.
- Write docstrings with a complete first sentence. Document arguments in
  uppercase, return values when non-obvious, side effects, errors, and prefix
  argument behavior for interactive commands.
- Use `interactive` specs for simple commands and `(interactive (list ...))`
  when arguments require validation or completion.
- Signal user mistakes with `user-error`; signal programmer or data errors with
  `error` or a specific condition. Preserve point, mark, buffer, window, and
  narrowing state with `save-excursion`, `save-restriction`, and related forms
  when commands inspect or rewrite buffers.
- Write macros only when a function cannot express the evaluation or binding
  semantics. Add `(declare (indent ...) (debug ...))`, use backquote, and use
  generated symbols for introduced bindings.

## Packaging Traps

- Keep `Package-Requires` aligned with actual dependencies. Do not list built-in
  libraries such as `cl-lib`, `seq`, or `subr-x` as external packages.
- Keep the provided feature name identical to the file's intended feature, and
  keep the footer filename identical to the file name.
- Do not introduce dependencies such as `dash`, `s`, `f`, or `ht` for simple
  operations that built-in Emacs APIs already cover.
- Avoid changing user customization names or autoloaded command names during
  cleanup unless migration compatibility is handled.
- Prefer `define-derived-mode`, `define-minor-mode`, and
  `define-globalized-minor-mode` over manually wiring mode variables.

## Validation

- Byte-compile modified example or package files with
  `emacs -Q --batch -L DIR -f batch-byte-compile FILE...`. Treat warnings as
  findings to inspect.

- For package code, run the project's ERT or Buttercup tests when present. If
  there is no test suite, use small batch evaluations that load the feature and
  exercise the changed commands or helpers.

- Run `checkdoc` or package-lint only when the project already uses them or the
  user asks for package-release polish.
