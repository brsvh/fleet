---
name: flake-lock-update
description: >
  Update and verify this repository's Nix flake lock files. Use when the user
  asks to update flake.lock, src/dev/flake.lock, shared flake inputs such as
  nixpkgs, nixos, systems, or all Nix flake inputs in this fleet repository.
---

# Flake Lock Update

Use this skill to update the two lock files in this repository:

- `flake.lock` for the repository root flake.
- `src/dev/flake.lock` for the development flake.

Default to updating both lock files in the same turn when the user does not
explicitly limit the request to one flake.

## Input Mapping

Treat these as the important top-level input relationships:

- Root flake: `nixos` is the upstream Nixpkgs input; `nixpkgs` follows
  `nixos`.
- Dev flake: `nixpkgs` is the upstream Nixpkgs input.
- Dev flake: `systems` is shared by `flake-utils` through `follows`.

When the user asks for `nixpkgs`, update root input `nixos` and dev input
`nixpkgs` unless they specify only one lock file. Do not update root input
`nixpkgs` directly because it follows `nixos`.

## Workflow

Run commands from the repository root.

1. Inspect current state:

   ```bash
   git status --short
   ```

2. Choose the update command:

   ```bash
   # Update every input in both lock files.
   nix flake update --flake .
   nix flake update --flake ./src/dev

   # Update the shared Nixpkgs upstream only.
   nix flake update --flake . nixos
   nix flake update --flake ./src/dev nixpkgs

   # Update named inputs when the same top-level input exists in both flakes.
   nix flake update --flake . <input>
   nix flake update --flake ./src/dev <input>
   ```

   If an input exists in only one flake, update only that flake and say so.

3. If Nix cannot fetch inputs because of network sandboxing, retry the same
   command with the required escalation rather than changing the update scope.

4. Verify the result:

   ```bash
   git status --short
   git diff -- flake.lock src/dev/flake.lock
   ```

   Report whether only the expected lock files changed. If other files changed
   before the update, do not revert them; mention that they were already present
   if relevant.

5. For broad updates or when the user asks for confidence checks, run the
   narrowest relevant Nix check available from local context. Prefer checking
   flake metadata before running expensive builds:

   ```bash
   nix flake metadata --flake .
   nix flake metadata --flake ./src/dev
   ```

## Reporting

Summarize:

- which inputs were updated in each lock file;
- whether the root and dev locks changed together;
- any command that could not be run and why;
- whether additional validation was run.

Keep lock diffs summarized unless the user asks for full diff output.
