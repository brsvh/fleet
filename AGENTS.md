# README for agents

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

- When writing, changing, generating, or restyling Nix code, use the
  `nix-coding` skill to refactor the code into the repository style.
- When writing, changing, generating, or restyling Emacs Lisp code, use the
  `emacs-lisp-coding` skill to follow the repository style.

## Activation and profile safety

- Do not run commands that activate, switch, roll back, or otherwise change the
  current NixOS generation, Home Manager generation, or Nix profile.
- Prohibited commands include `nixos-rebuild switch`, `nixos-rebuild boot`,
  `nixos-rebuild test`, `home-manager switch`, generated Home Manager `activate`
  scripts, `nix profile install`, `nix profile upgrade`, `nix profile remove`,
  `nix profile rollback`, `nix-env --switch-generation`, `nix-env --rollback`,
  and similar commands that mutate the active generation or profile.
- Prefer non-activating validation commands such as `nix flake check`,
  `nix build`, `nix eval`, `nixos-rebuild build`, and `home-manager build`.
- If activation or profile switching is needed, stop after building or
  evaluating and ask the user to run the activating command themselves.

## Commit message rules

- Use the `commit` skill for commit message style.
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
