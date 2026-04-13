---
name: commit-message
description: >
  Generate a final git commit message for this repository, or create the commit
  after showing the message and getting explicit user confirmation. Use when
  asked to write a commit message or commit the current staged changes.
---

# Commit Message

Use this skill when the user wants a final commit message for this repository,
or wants the staged changes committed.

## Required workflow

Run these commands in order from the repo root:

1. `git status --short`
2. `git diff --cached --stat`
3. `git diff --cached`

Do not skip these checks.

If nothing is staged, say so clearly and ask whether the user wants a message
for unstaged changes instead.

## Commit automation

Default to message-only mode when the user asks for a commit message, runs
`$commit-message`, or does not explicitly ask you to create a commit.

Use commit mode only when the user explicitly asks you to commit the staged
changes.

In commit mode:

1. Complete the required workflow above.
2. Draft the final commit message using the repository rules below.
3. Show the exact commit message to the user.
4. Ask for explicit confirmation before running `git commit`.
5. Do not run `git commit` until the user confirms.
6. After confirmation, write the message to a temporary file and run
   `git commit -F <temporary-file>`.
7. Report the commit result, including the new commit hash when available.

If the user changes the staged set before confirming, repeat the required
workflow and regenerate the message before committing.

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

In message-only mode, produce exactly one final commit message.

Output only the commit message text unless the user explicitly asks for
explanation.

In commit mode, show the exact proposed commit message and ask for confirmation
before committing.
