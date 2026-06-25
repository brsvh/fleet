# GNU-style commit message reference

## Style classification

This skill uses a portable GNU-style commit message variant.

A commit message consists of:

1. a scoped subject line;

1. a blank separator line;

1. a required GNU-style file bullet list body;

1. optional trailers only when the user or target repository requires them.

The message must describe all staged changes as one commit.

## Required input

Before drafting a commit message, inspect staged changes with:

- `git status --short`
- `git diff --cached --stat`
- `git diff --cached`

The commit message must describe staged changes only.

If scope selection is ambiguous, inspect lightweight local context such as
recent commit subjects or documented contribution rules:

- `git log --format=%s -n 50`
- `CONTRIBUTING*`, `HACKING*`, `README*`, or similar repository guidance

Use this local context only to choose a truthful scope or subscope. Do not copy
unrelated project names from examples.

## Subject format

Use exactly one of the following forms:

```text
<scope>: <subscope>: <Verb> <summary>
<scope>: <Verb> <summary>
```

Rules:

1. Scope and subscope tokens must be lowercase.

1. Prefer scope tokens already established by the target repository.

1. The verb must be imperative and capitalized.

1. The subject must not end with a period.

1. Prefer subjects within `60` characters.

1. The subject must remain concise even when approaching the limit.

1. Use the narrowest truthful scope supported by the staged paths and staged
   diff.

1. Use the two-level form when one concrete component clearly dominates the
   change.

1. Use the one-level form when the change is area-wide, cross-cutting within one
   area, or no honest single subscope exists.

## Deriving `scope`

Derive the top-level scope from the staged paths, staged diff, and target
repository conventions.

Apply these rules in order:

1. If the target repository documents compatible scope rules, follow them.

1. If recent commit subjects consistently use a scope token for the staged area,
   prefer that established token.

1. If all staged changes are documentation-only, use the repository's
   documentation scope if one exists; otherwise use `doc`.

1. If the staged changes clearly belong to one source package, module, service,
   command, library, plugin, skill, or profile, use that stable component name.

1. If all staged paths share a meaningful top-level directory, use that
   directory name after normalizing it to a lowercase scope token.

1. For repository-wide changes, top-level metadata, package manifests, or shared
   wiring, use the project-name scope.

1. If no narrow truthful scope exists, use the project-name scope.

Project-name scope:

1. Look for a project name in repository-root files in this order: `README`,
   `README.md`, then `README.org`.

1. Prefer the first meaningful document title, such as the first Markdown H1,
   setext heading, Org title/level-one heading, or plain README title line.

1. If no project name is found in those files, use the target repository root
   directory name.

1. Normalize the selected project name using the scope normalization rules
   below.

Normalization rules:

1. Keep established repository spelling when it is already lowercase.

1. Lowercase any uppercase letters in derived names.

1. Convert spaces and underscores to hyphens.

1. Drop file extensions from file-derived scopes.

1. Avoid punctuation other than hyphens.

1. Do not use placeholder or example scopes unless they match the target
   repository.

Common portable scopes include:

- `build`
- `ci`
- `cli`
- `config`
- `doc`
- `lib`
- `test`
- `ui`

This list is not exhaustive. Prefer the target repository's own vocabulary over
these generic examples.

## Deriving `subscope`

`subscope` is optional.

Rules:

1. Use a subscope only when one stable component under the chosen top-level
   scope clearly dominates the staged changes.

1. Prefer established module, package, command, feature, profile, plugin, skill,
   or service names already used in the repository.

1. For changes under a repeated collection such as `plugins/<name>/`,
   `skills/<name>/`, `packages/<name>/`, or `services/<name>/`, use `<name>` as
   the subscope when all staged changes belong to the same item.

1. Do not invent a subscope that is not supported by the staged diff.

1. If the change crosses multiple components under one top-level scope, omit the
   subscope.

## Preferred verbs

Use the most precise imperative verb that matches the staged diff.

Preferred verbs include:

- `Add`
- `Update`
- `Remove`
- `Move`
- `Fix`
- `Enable`
- `Configure`
- `Import`
- `Use`
- `Set`
- `Bump`
- `Rename`
- `Expose`
- `Switch`
- `Generalize`

Prefer established verbs documented in this file when they fit the change.

## Body policy

A body is always required.

Rules:

1. Always insert exactly one blank line after the subject.

1. Always include a file bullet list body, even for a single-file or trivial
   change.

1. The body must cover the staged files and must not describe unstaged changes.

## Body format

Write the body as GNU-style file bullets.

Each bullet must use this form:

```text
* <path>: <Description...>
```

Rules:

1. Use one bullet per changed file whenever practical.
1. Sort bullets by `<path>` in ascending lexicographic order.
1. Start each bullet description with an uppercase letter.
1. End each bullet description with a period.
1. Keep each bullet concise and file-oriented.
1. State what the file change does.
1. Include why only when needed.
1. Do not replace the bullet list with free-form prose.
1. Do not write `This commit ...`.

## Wrapping rules

Wrap body lines for readability in GNU style.

Rules:

1. Keep body lines within `70` characters.
1. Do not indent continuation lines.
1. Do not leave trailing spaces before a newline.
1. If a bullet wraps, continue on the next line at column `0`.
1. Do not repeat `* <path>:` on continuation lines.

Example:

```text
* src/parser/options.c: Add shared option validation for quoted
values.
```

## Trailer policy

Do not add trailers unless the user or target repository requires them.

When an assistance trailer is required, place it after exactly one blank line
following the body bullets:

```text
Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]
```

Fill `AGENT_NAME` at skill invocation time by resolving the actual current agent
identity from the running session or its configuration. Do not default it to any
product, tool, or platform name unless that is the configured current agent
name.

For `MODEL_VERSION`, at commit-skill execution time, first inspect the
configuration file or inline configuration entry that defines the current agent
and use its exact `model` value. If the current agent configuration cannot be
located or does not set a model, fall back to the most specific model value
exposed by the active session context. Do not include example model labels or
hard-code either value in this skill; the trailer must use values discovered at
execution time. Omit tool tokens unless a specialized analysis tool was actually
called while preparing the commit.

## Scope fallback

If scope selection is ambiguous, apply this fallback order:

1. Use the two-level form when one component clearly dominates.

1. Otherwise use the one-level form.

1. Use a documented or recently used scope from the target repository when it
   truthfully describes the staged changes.

1. Use the project-name scope for repository-wide changes.

1. Use the project-name scope when no narrower truthful scope exists.

## Content rules

1. Describe all staged changes in one commit message.

1. Keep the subject concise and specific.

1. Keep bullet descriptions concrete and file-oriented.

1. Avoid fluff.

1. Do not use emojis.

1. Do not use decorative Unicode.

1. Do not include URLs or links.

1. Do not use Conventional Commit prefixes unless explicitly requested.

## Recommended examples

- `doc: Update installation notes`
- `build: Fix release artifact naming`
- `parser: Handle quoted field escapes`
- `ui: settings: Add profile import action`
- `skills: commit: Generalize scope fallback`
