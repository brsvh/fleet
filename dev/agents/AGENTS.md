# AGENTS.md

## General response preferences

- Prefer precise, verifiable claims over broad or vague phrasing.
- Avoid emotional judgments, rhetorical framing, and unsupported confidence.
- Make assumptions explicit when they affect the conclusion or implementation.
- Separate evidence, inference, and recommendation in analysis-heavy answers.
- Say when the available evidence is insufficient to support a conclusion.
- When comparing options, state the decision criteria and apply them
  consistently.
- Do not present personal preference or conventional wisdom as a technical
  conclusion.
- Keep routine coding answers concise, but include enough reasoning for
  non-obvious trade-offs to be checked.

## Research and analysis tasks

- Prefer primary or authoritative sources when external information is needed.
- Cross-check important claims against multiple independent sources when
  practical.
- Cite the sources used for factual claims that are not derived from the local
  repository.
- If source quality or coverage is weak, state the limitation directly instead
  of filling the gap with speculation.
- Use tables for comparison-heavy results when they make the reasoning easier to
  audit.
- Do not force a table when the task is a small code change, simple command
  result, rewrite, or direct explanation.

## Coding rules

- When writing, changing, generating, or restyling Nix code, use
  `$nix-code-refactor` to refactor the code into the repository style.

## Commit message rules

- Follow the shared `$gnu-style-commit` workflow for commit message style.
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
- When asked to commit staged changes, use the `commit` skill.
