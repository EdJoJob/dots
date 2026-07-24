---
status: accepted
date: 2026-07-22
---

# Machine- and identity-specific config lives in a private side-car repo

## Context and Problem Statement

Some config is machine- or identity-specific (work email, ssh hosts,
signing keys, secrets maps, per-machine tool lists) and must never be in
the public repo. Previously these were loose untracked `~/.local_*` files
touch-created by the installer — unversioned, unbacked-up, and invisible.

## Decision Drivers

- Nothing private or machine-specific may be committed publicly.
- Local files should still be versioned and recoverable per machine.
- Every tracked public config must degrade gracefully when the local file
  is absent (guarded includes, no touch-created empties).

## Considered Options

- **Private side-car repo, deployed by the same tool** — chosen.
- Encrypted-in-repo secrets (git-crypt / chezmoi templates) — fights the
  plain-symlink model and puts ciphertext in the public history.
- Keep untracked `~/.local_*` files — status quo; unversioned.

## Decision Outcome

A second stow-style repo (the *side-car*, e.g. `~/src/local-dots`) with the
same `packages/` + `manifests/` layout, deployed by the same `dots link`
run. `templates/local-dots/` in this repo is the public scaffold for it
(`dots sidecar-init` seeds a new one). The contract it owns: `.local_zshrc`,
`.local_gitconfig`, `.local_tmux.conf`, `.local_vimrc`, `~/.ssh/config.d/*`,
`~/.ssh/allowed_signers`, `~/.config/dots/secrets.map`, mise `conf.d`
fragments, mail account files.

### Consequences

- Good: private config is versioned per machine; cross-repo path claims
  hard-error via the `dots` conflict contract.
- Bad: two repos to keep pushed; bootstrap needs `--sidecar <url>`.
