---
status: accepted
date: 2026-07-23
---

# topgrade replaces the hand-maintained update-all script

## Context and Problem Statement

`update-all` was hand-maintained glue that knew about each package manager
individually and needed editing every time one was added or retired.

## Considered Options

- **topgrade** — chosen: single cross-platform updater that discovers
  brew/apt/dnf/mise/zi/tmux/nvim-plugin steps itself.
- Keep maintaining `update-all` — perpetual drift.

## Decision Outcome

topgrade (installed via mise, per
[0006](0006-mise-first-tool-management.md)) with a tracked
`~/.config/topgrade.toml`. Muscle memory is preserved by an `update-all`
alias. The config keeps nvim plugin updates **lockfile-respecting** so
`lazy-lock.json` stays the source of truth
(see [0008](0008-neovim-only-lazy-nvim-native-lsp.md)).

### Consequences

- Good: zero glue to maintain; new tools are covered automatically.
- Bad: topgrade's auto-discovery can be eager — disabled steps live in
  `topgrade.toml` rather than in script logic.
