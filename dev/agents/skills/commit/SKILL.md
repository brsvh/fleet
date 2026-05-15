---
name: commit
description: >-
  Commit the staged changes in this repository by invoking the GNU-style commit
  skill.
---

# Commit

Use this skill when the user wants staged changes in this repository committed.

## Required workflow

Immediately invoke `$gnu-style-commit` from the repository root.

Do not reimplement, summarize, or override `$gnu-style-commit`'s workflow,
message checks, or output format in this skill. Treat this skill only as the
repository-specific alias for the shared GNU-style commit workflow.
