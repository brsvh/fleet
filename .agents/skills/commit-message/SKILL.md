---
name: commit-message
description: >
  Generate a final git commit message for this repository, or create the commit
  when explicitly asked. Use when asked to write a commit message or commit the
  current staged changes.
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
3. Check the final message text using the checklist below.
4. Write the message to a temporary file and run
   `git commit -F <temporary-file>`.
5. Report the commit result, including the new commit hash when available.

Do not pause after the user's explicit commit request. Treat that request as
authorization to create the commit. If the environment blocks access to `.git`,
retry with the required sandbox escalation and continue after access is
available.

In commit mode, do not stop after drafting the message and do not ask the user
to type another prompt. The message drafting step and `git commit -F` step are
one uninterrupted workflow.

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
- wrap body lines to at most 70 columns in GNU style without indenting
  continuation lines.

Before producing or committing a message, check the final message text:

- the subject must use one allowed scope form;
- exactly one blank line must separate the subject from the body;
- every body line must be 70 columns or shorter;
- wrapped bullet continuations must start at column 0;
- every bullet must end with a period.

## Output format

In message-only mode, produce exactly one final commit message.

Output only the commit message text unless the user explicitly asks for
explanation.

In commit mode, do not output only a proposed message. Commit with the generated
message first, then report the result.
