---
status: accepted
date: 2026-08-10
---

# zsh completion for dots: dynamic package globbing, not a generated list

## Context and Problem Statement

`dots` (see [0003](0003-gnu-stow-via-dots-wrapper.md)) has no shell completion.
The awkward part isn't the subcommands or flags — it's `pkg` arguments: the
valid set is just "directory names under `packages/` in whichever repo is
active", and that set changes every time a package is added, removed, or a
side-car repo is configured. A completion source that can go stale is worse
than none.

## Considered Options

- **Dynamic glob at completion time** — chosen: the completion function
  resolves both repos the same way `dots` does and globs `packages/*/` on
  every `<TAB>`. Main repo: `DOTS_REPO`, else the resolved `dots` script's
  directory, else `~/dots`. Side-car (`find_sidecar`, dots:69-83):
  `DOTS_SIDECAR` (taken unconditionally, with no `packages/` check), else the
  first line of `${XDG_CONFIG_HOME:-~/.config}/dots/sidecar` with a leading
  `~` expanded, else `~/src/local-dots`, else `~/dots-local`. The completion
  function then requires `<repo>/packages` to exist before globbing, so a
  stale or half-configured side-car contributes nothing rather than erroring.
- Static list baked into the completion file — would need regenerating by
  hand or a build step every time a package changes; rejected as a
  maintenance trap.
- Shell out to `dots list` — `dots list` formats per-file deploy state for
  humans; parsing it for names is slower and more brittle than a glob.

## Decision Outcome

New file `packages/zsh/.zfunc/_dots`, `#compdef dots` as its first line.
`packages/zsh/.zshrc:10` already puts `$HOME/.zfunc` on `fpath`, so stow
deploying the file is sufficient; no `.zshrc` change is needed for
autoloading. Note `~/.zfunc` is currently materialised by the side-car
(`local-dots/packages/core/.zfunc/`), not by `packages/zsh` — `_dots` is the
first main-repo file there, and `--no-folding` ([0003](0003-gnu-stow-via-dots-wrapper.md))
is what lets both repos populate that one directory without tripping
`overlap_check`.

The function completes subcommands (`link`, `unlink`, `relink`/`restow`,
`adopt`, `doctor`, `migrate-legacy`, `list`, `sidecar-init`, `help`), each
subcommand's real argument surface, and package names via a live glob of
`packages/*/`:

| subcommand | options | positionals |
| --- | --- | --- |
| `link` / `unlink` / `relink` / `restow` | `-n`/`--dry-run` | pkg names (union of both repos) |
| `adopt` | `-s`/`--sidecar`, `-p`/`--package` | existing files under `~` |
| `migrate-legacy` | `-n`/`--dry-run` | none — it rejects positionals |
| `sidecar-init` | none | one optional url-or-path |
| `doctor` / `list` / `help` | none | none |

`adopt`'s positionals are the point of the command, so they complete as
regular files under `$HOME` (`cmd_adopt` requires `$HOME/*`, and rejects
symlinks and non-regular files).

Package-name completion also mirrors which repo `dots` itself would act on,
because `dots` spans two repos ([0004](0004-private-sidecar-repo.md)):

- `link`/`unlink`/`relink`/`restow` select packages from **both** repos in a
  single run, so completion unions `packages/*/` from `MAIN_REPO` and
  `SIDECAR`. Deliberately the union of `packages/*/`, **not** the manifest
  selection: `cmd_stow_action` accepts any name present in either repo's
  `packages/`, so completion is intentionally a superset of what a bare
  `dots link` would pick. Matching `packages_for` instead would hide every
  opt-in package from `<TAB>`.
- `adopt` targets exactly **one** repo per invocation, chosen by whether
  `-s`/`--sidecar` was passed. Completion inspects the already-typed words:
  if `-s`/`--sidecar` is present, `-p`'s value completes from
  `SIDECAR/packages/*/` only; otherwise from `MAIN_REPO/packages/*/` only.
  Offering the other repo's package names would suggest creating or
  adopting into the wrong repo.

### Consequences

- Good: completions never go stale; no generation step to remember.
- Good: rides the existing `.zfunc` autoload convention — no new fpath entry.
- Good: completion candidates always match the repo `dots` would actually
  touch, so tab-completing `-p` never suggests a name from the wrong repo.
- Bad: repo-resolution logic is duplicated (dots itself + the completion
  function, for both `MAIN_REPO` and `SIDECAR`); if `find_main_repo`'s or
  `find_sidecar`'s resolution order in `dots` changes, the completion
  function needs a matching update.
- Bad: the same duplication applies to the argument surface — a new
  subcommand or option in `dots` needs a matching arm in `_dots`.
- Neutral: `compinit` is deferred here (`zinit wait lucid … atinit"zicompinit;
  zicdreplay"`), so a first-install may need `rm -f ~/.zcompdump*` once if a
  cached dump predates the new function. Not a design constraint, just a
  first-run note.
