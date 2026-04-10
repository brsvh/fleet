---
name: commit-message-review
description: >
  Generate and review commit message candidates for this repository. Use when
  asked to compare, refine, or review candidate commit messages for the current
  staged changes.
---

# Commit Message Review

Use this skill when the user wants alternatives, comparison, or review for a
commit message in this repository.

## Required workflow

Run these commands in order from the repo root:

1. `git status --short`
2. `git diff --cached --stat`
3. `git diff --cached`

Do not skip these checks.

If nothing is staged, say so clearly and ask whether the user wants candidates
for unstaged changes instead.

## Repository rules

Follow `docs/commit-message-style.md`.

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

Produce exactly three candidates.

For each candidate:

1. show the full commit message;
2. explain in one short sentence why it fits the staged diff and repository
   rules.

Then mark one candidate as **Recommended** and explain briefly why it is the
best match for:

- scope precision;
- verb choice;
- body coverage of the staged files.
