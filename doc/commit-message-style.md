# Commit message style

## Style classification

This repository uses a GNU-style commit message variant.

A commit message consists of:

1. a scoped subject line;

2. a blank separator line;

3. a required GNU-style file bullet list body.

The message must describe all staged changes as one commit.

## Required input

Before drafting a commit message, inspect staged changes with:

- `git status --short`
- `git diff --cached --stat`
- `git diff --cached`

The commit message must describe staged changes only.

## Subject format

Use exactly one of the following forms:

```text
<scope>: <subscope>: <Verb> <summary>
<scope>: <Verb> <summary>
````

Rules:

1. Scope tokens must be lowercase.

2. The verb must be imperative and capitalized.

3. The subject must not end with a period.

4. Prefer subjects within `60` characters.

5. The subject must remain concise even when approaching the limit.

6. Use the narrowest truthful scope supported by the staged paths and staged
diff.

7. Use the two-level form when one concrete component clearly dominates the
change.

8. Use the one-level form when the change is area-wide, cross-cutting within one
area, or no honest single subscope exists.

## Deriving `scope`

Derive the top-level scope from staged paths, with repository root as
`PRJ_ROOT`.

Apply the following rules in order:

1. If any staged path matches `^doc/`, use `doc`.

   - This rule overrides all lower-priority scope rules.

2. If all staged paths are either `AGENTS.md` or under `.agents/`, use `agents`.

   - This rule overrides all remaining non-`doc` scope rules.

3. Otherwise, collect staged paths matching `^src/([^/]+)/`.

   - Extract the first directory under `src/`.
   - If one value clearly dominates, use it as the top-level scope.
   - If multiple values appear and no single value dominates, choose the most
     appropriate single scope that best describes the staged changes.
   - If no honest single choice is possible, use `fleet`.

4. Otherwise, if all staged paths are directly under `PRJ_ROOT` and contain no
   `/`, use `fleet`.

5. Otherwise, use `fleet`.

Common top-level scopes include:

- `agents`
- `azaleoid`
- `system`
- `home`
- `bingshan`
- `fleet`
- `dev`
- `doc`
- `root`

## Deriving `subscope`

`subscope` is optional.

Rules:

1. If `scope` is `agents` and all staged paths under `.agents/skills/` belong to
   the same skill directory `.agents/skills/<name>/`, use `<name>` as the
   subscope.

2. If `scope` is `agents` and the staged changes touch `AGENTS.md`, `.agents/`
   content outside `.agents/skills/`, or multiple skill directories under
   `.agents/skills/`, then omit the subscope.

3. For non-`agents` scopes, use a subscope only when one stable component under
   the chosen top-level scope clearly dominates the staged changes.

4. Prefer established module, profile, or component names already used in the
   repository.

5. Do not invent a subscope that is not supported by the staged diff.

6. If the change crosses multiple components under one top-level scope, omit the
   subscope.

Common subscopes include:

- `commit-message`
- `commit-message-review`
- `nixpkgs`
- `gnome`
- `emacs`
- `swap`
- `fish`
- `xdg`
- `disko`
- `sops`
- `gdm`
- `gnupg`
- `git`
- `bash`
- `locale`
- `codex`
- `fonts`
- `chromium`
- `direnv`

## Preferred verbs

Use the most precise imperative verb that matches the staged diff.

Preferred verbs include:

* `Add`
* `Update`
* `Remove`
* `Move`
* `Fix`
* `Enable`
* `Configure`
* `Import`
* `Use`
* `Set`
* `Bump`
* `Rename`
* `Expose`
* `Switch`

Prefer established verbs documented in this file when they fit the change.

## Body policy

A body is always required.

Rules:

1. Always insert exactly one blank line after the subject.

2. Always include a file bullet list body, even for a single-file or trivial
change.

3. The body must cover the staged files and must not describe unstaged changes.

## Body format

Write the body as GNU-style file bullets.

Each bullet must use this form:

```text
* <path>: <Description...>
```

Rules:

1. Use one bullet per changed file whenever practical.
2. Sort bullets by `<path>` in ascending lexicographic order.
3. Start each bullet description with an uppercase letter.
4. End each bullet description with a period.
5. Keep each bullet concise and file-oriented.
6. State what the file change does.
7. Include why only when needed.
8. Do not replace the bullet list with free-form prose.
9. Do not write `This commit ...`.

## Wrapping rules

Wrap lines for readability in GNU style.

Rules:

1. Prefer keeping lines within `72` characters.
2. Do not indent continuation lines.
3. Do not leave trailing spaces before a newline.
4. If a bullet wraps, continue on the next line at column `0`.
5. Do not repeat `* <path>:` on continuation lines.

Example:

```text
* src/system/foo.nix: Add shared option wiring for the new
module.
```

## Scope fallback

If scope selection is ambiguous, apply the following fallback order:

1. Use the two-level form when one component clearly dominates.

2. Otherwise use the one-level form.

3. Use `fleet` for repository-wide or shared flake, export, wiring, docs, or
top-level structure changes when no narrower truthful scope exists.

4. Use `dev` for development tooling or local developer experience changes.

5. If `doc/` is touched, use `doc` regardless of other staged paths.

## Content rules

1. Describe all staged changes in one commit message.

2. Keep the subject concise and specific.

3. Keep bullet descriptions concrete and file-oriented.

4. Avoid fluff.

5. Do not use emojis.

6. Do not use decorative Unicode.

7. Do not include URLs or links.

8. Do not use Conventional Commit prefixes unless explicitly requested.

## Recommended examples

- `agents: Update commit message routing rules`
- `agents: commit-message: Split generation workflow`
- `agents: commit-message-review: Remove history lookup`
- `home: fonts: Add default font profile`
- `system: fish: Update shell abbreviations`
- `azaleoid: nixpkgs: Remove redundant overlay wiring`
- `fleet: Expose module exports`
- `dev: Bump flake inputs`
- `doc: Update installation notes`

## Invalid forms

Avoid the following:

* `feat(home): add fonts profile`
* `Add fonts profile`
* `home/fonts add fonts profile`
* `home: fonts: added default font profile.`
* subjects without a body
* bodies written as free-form prose without path anchors
* scopes broader than the staged files support
