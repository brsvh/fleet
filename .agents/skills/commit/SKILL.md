---
name: commit
description: >
  Commit the staged changes in this repository using the repository's commit
  message rules.
---

# Commit

Use this skill when the user wants the staged changes committed.

## Required workflow

Run these commands in order from the repo root:

1. `git status --short`
2. `git diff --cached --stat`
3. `git diff --cached`

Do not skip these checks.

If nothing is staged, say so clearly and stop.

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

## Repository rules

Follow `.agents/doc/commit-message-style.md`.

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

Do not output only a proposed message. Commit with the generated message first,
then report the result.
