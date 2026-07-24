---
status: accepted
date: 2026-07-22
---

# Secrets: seed once from 1Password into the OS keychain

## Context and Problem Statement

Configs and services need credentials (API tokens, notification topics,
mail passwords). 1Password is the source of truth, but `op read` takes
seconds and needs an interactive session — unusable from daemons, timers,
or anything sourced at shell startup. Plaintext `~/.local_*` tokens are the
status quo being replaced.

## Decision Drivers

- Runtime reads must be fast (prompt paths, launchd/systemd units).
- No interactive prompt at read time; works while logged in.
- Secrets never enter either repo; rotation stays a one-command affair.

## Considered Options

- **Seed once into the OS keychain, read natively** — chosen.
- `op read` at each access — seconds-slow, needs a TTY/biometric session;
  **banned from daemons, timers, and shell-startup paths**.
- Plaintext files in the side-car — what this replaces; acceptable only on
  truly headless boxes.
- Environment variables exported at login — leak-prone, no rotation story.

## Decision Outcome

The `secret` helper (`bin` package):

- `secret seed` reads `~/.config/dots/secrets.map` (side-car-owned,
  `name → op://` reference) through 1Password **once** at install/rotation
  time and stores each value in the login keychain (macOS `security`,
  Linux `secret-tool`/libsecret).
- `secret get <name>` is the only runtime read: ~30ms, non-interactive,
  readable by launchd agents / systemd user units while logged in. Items
  are created and read by the same binary, so the macOS keychain ACL never
  prompts.

Only `secret seed`/`secret set` may invoke `op`, and only interactively.

### Consequences

- Good: daemon-safe, fast, rotation = edit 1Password + re-seed.
- Bad: the prompt-free ACL cuts both ways — any process running as the
  user can read seeded items silently. Seed only what services actually
  consume; keep high-value material behind `op` prompts.
- Linux shares the pattern via libsecret with the usual session-keyring
  caveat; headless boxes fall back to plain side-car files.
