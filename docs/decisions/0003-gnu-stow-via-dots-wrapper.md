---
status: accepted
date: 2026-07-22
---

# Deploy dotfiles with GNU Stow via the `dots` wrapper

## Context and Problem Statement

The old deployment was a hand-rolled `install/link.sh` find-loop over
`*.symlink` files with special cases. It silently overwrote, could not
express per-platform selection, and had no adopt/undeploy story. A
replacement deployer was needed.

## Decision Drivers

- Two repos must deploy into one `$HOME`: this public repo plus a private
  side-car (see [0004](0004-private-sidecar-repo.md)).
- A path claimed twice, or a real file in the way, must **hard-error before
  any mutation** — never silent first-wins.
- Must be able to adopt an existing live file under management.
- Must be installable from the default package manager on macOS (brew),
  Debian/Ubuntu (apt), and RedHat (dnf/EPEL).

## Considered Options

| Tool           | Two repos         | Hard conflict error            | Adopt       | brew/apt/dnf/EPEL          | Score |
| ---            | ---               | ---                            | ---         | ---                        | ---   |
| **stow 2.4.1** | yes (2 stow dirs) | yes — all-or-nothing abort     | via wrapper | all four                   | 7.5   |
| rcm 1.3.6      | yes (native)      | no — silent first-wins         | yes (mkrc)  | all but EPEL10             | 6.5   |
| dotbot 1.24.1  | wrapper glue      | yes                            | no          | brew only (vendors itself) | 6.5   |
| chezmoi 2.71   | fights design     | opt-in flag, v2.71+ only       | partial     | no stable apt              | 4.5   |
| yadm 3.5       | no                | no                             | yes         | retired from Fedora/EPEL   | 4.0   |

Also surveyed: bare-git, make/ln, home-manager, dotter, tuckr, rotz, lnk,
mackup — none beat the above on these requirements. `tuckr` (Rust,
brew-only) is the credible stow successor if the UX ever grates.

## Decision Outcome

GNU Stow, driven by the `./dots` wrapper (bash 3.2 compatible), which adds
what stow lacks: cross-repo conflict detection, `adopt`, `doctor`,
`migrate-legacy`, manifests. Conventions locked in:

- **Literal dot-named files** in `packages/<pkg>/<literal $HOME path>` — no
  `--dotfiles` flag (broken on the stow 2.3.1 shipped by Debian 12 /
  Ubuntu 24.04).
- **`--no-folding` everywhere**: both repos coexist under `~/.config`, and
  app-written files must not land inside the repo.
- The wrapper is named `dots`, not `dot` — graphviz ships a `dot` binary
  that shadows it.

### Consequences

- Good: conflicts abort atomically; regression tests pin the contract.
- Bad: stow's own CLI is never used directly; all flows go through `dots`.
