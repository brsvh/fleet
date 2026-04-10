## Commit message rules

- Follow `doc/commit-message-style.md`.
- Describe staged changes only.
- Use only `scope: Verb summary` or `scope: subscope: Verb summary`.
- Derive scope from staged paths and staged diff.
- Keep scope tokens lowercase, use an imperative capitalized verb, and omit the
  trailing period in the subject.
- Prefer the two-level form when one component dominates; otherwise use the
  one-level form.
- Always include a body after exactly one blank line.
- Write the body as `* path: change.` bullets with concise file-oriented
  sentences.
- When asked to write a commit message, use the `commit-message` skill.
- When asked to compare, review, or refine commit message candidates, use the
  `commit-message-review` skill.
