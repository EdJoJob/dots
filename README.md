# dots

Personal dotfiles, deployed with [GNU Stow](https://www.gnu.org/software/stow/)
via the `./dots` wrapper, plus a **private side-car repo** for anything
machine- or identity-specific.

```sh
git clone git@github.com:EdJoJob/dots.git ~/dots
cd ~/dots && ./install.sh --sidecar <private-repo-url>
```

- [docs/INSTALL.md](docs/INSTALL.md) — new-machine bootstrap (macOS, Debian, RedHat)
- [docs/MANAGING.md](docs/MANAGING.md) — day-to-day: link, adopt, side-car, conflicts
- [docs/decisions/](docs/decisions/) — decision records (MADR): what was chosen, and the alternatives considered

## Rules

- Everything deployable lives in `packages/<pkg>/` at its **literal**
  `$HOME`-relative path; `manifests/` picks packages per platform.
- Two repos, one flow: `dots link` deploys this repo and the side-car, and
  **hard-errors** if they claim the same path or anything is in the way.
- `dots adopt <file>` moves an existing file under management and leaves a
  symlink; `-s` targets the side-car.
- Machine-specific config = `~/.local_*` files and `~/.ssh/config.d/*`,
  shipped by the side-car; every tracked config degrades gracefully when
  they're absent.

## The list of what tools I use for what

_because otherwise **I** forget_

* File Watching: `entr`
* Editing: `nvim` (aliased to `vi` because I am extremely lazy AND often on remote systems)
* Repeated commands: `watch` from procps-ng
* Shell: `zsh` (plugins via `zi`, self-bootstrapping)
* Browser: `firefox` for TreeStyleTabs (chrome CSS in `misc/firefox/`)
* Window management (macOS): AeroSpace
* Normal Regex Searching: `rg` for rip-grep
* ngrok: for ad-hoc port-forwarding and/or NAT punch-through
* `gron` and `jq`: look through json; `xq` for XML, `yq` for yaml
* `xprop` to get X-Window Properties (window rules in tiling WMs)
* `neomutt` + `lieer` + `notmuch` for Gmail-as-vfolders (offlineimap/davmail kept as legacy reference — see docs/MAIL.md; opt-in `mail` package)
* `vdirsyncer` and `khard` for a "real" local calendar
* `eza` for ls replacement
* `mise` for language/tool versions
