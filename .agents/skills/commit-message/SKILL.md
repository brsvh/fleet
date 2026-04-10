---
name: commit-message
description: >
  Generate a final git commit message for this repository. Use when asked to
  write a commit message for the current staged changes.
---

# Commit Message

Use this skill when the user wants a final commit message for this repository.

## Required workflow

Run these commands in order from the repo root:

1. `git status --short`
2. `git diff --cached --stat`
3. `git diff --cached`

Do not skip these checks.

If nothing is staged, say so clearly and ask whether the user wants a message
for unstaged changes instead.

## Repository rules

Follow `doc/commit-message-style.md`.

Hard requirements:

- describe staged changes only;
- use only `scope: Verb summary` or `scope: subscope: Verb summary`;
- derive scope from staged paths and staged diff;
- keep scope tokens lowercase;
- use an imperative capitalized verb;
- omit the trailing period in the subject;
- always include a body after exactly one blank line;
- write the body as `* path: change.` bullets;
- sort bullets by path in ascending lexicographic order;
- keep bullets concise and file-oriented;
- wrap long lines in GNU style without indenting continuation lines.

## Output format

Produce exactly one final commit message.

Output only the commit message text unless the user explicitly asks for
explanation.
