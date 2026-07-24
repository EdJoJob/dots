---
status: accepted
date: 2026-07-23
---

# Tool installation: mise first, uv for Python tools, OS packages last

## Context and Problem Statement

CLI tools were installed by a zoo of per-OS scripts (brew, apt, pipx, npm,
ruby, rust) that drifted apart. Unpackaged and language-ecosystem tools
should land identically on macOS, Debian, and RedHat from one declarative
manifest.

## Decision Drivers

- One manifest, one mechanism, identical across platforms.
- Declarative and versionable; per-machine additions without forking it.
- Daemons and timers must find the installed tools.

## Considered Options

- **mise-first hierarchy** — chosen.
- Keep per-OS package scripts — three managers drifting; the status quo.
- pipx for Python tools — retired outright in favour of uv.

## Decision Outcome

Hierarchy, in order:

1. **mise** (npm / uvx / github backends), declared in
   `packages/mise/.config/mise/config.toml` — the default home for any
   CLI tool (LSP servers, lieer, topgrade, ...).
2. **uv/uvx** for Python tools (mise setting `pipx.uvx = true`); pipx is
   fully retired.
3. **brew/apt/dnf only for C-linked system tools** properly packaged
   everywhere (zsh, stow, tmux, notmuch, gopls) — `install/Brewfile`,
   `install/packages-{apt,dnf}.txt`.

Per-machine tools go in side-car `~/.config/mise/conf.d/*.toml` fragments.
Anything a service invokes must resolve via `~/.local/share/mise/shims` on
PATH. `install.sh --tools` drives `install/tools.sh` after linking (it
reads the stowed mise config).

### Consequences

- Good: one lockstep manifest; per-machine deltas stay in the side-car.
- Bad: mise becomes a bootstrap dependency; shims must be on PATH for
  daemons or their tools silently vanish.
