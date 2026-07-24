# Installing on a new machine

## TL;DR

```sh
git clone git@github.com:EdJoJob/dots.git ~/dots
cd ~/dots
./install.sh --sidecar thoth:/volume1/git/local-dots   # or your side-car URL
```

That is: clone, bootstrap. `install.sh` installs GNU Stow and zsh via the
platform package manager, clones the private side-car, symlinks everything
with hard-error conflict detection, and runs `dots doctor`.

## Prerequisites per platform

| Platform | Needs first | Stow comes from |
|---|---|---|
| macOS | [Homebrew](https://brew.sh) | `brew install stow` |
| Debian/Ubuntu | nothing | `apt-get install stow` |
| Fedora | nothing | `dnf install stow` |
| RHEL/Alma/Rocky | EPEL: `sudo dnf install epel-release` | `dnf install stow` (EPEL) |

Stow ≥ 2.3.1 works; ≥ 2.4.0 preferred. The repo deliberately avoids stow's
`--dotfiles` mode, which is broken for directories in the 2.3.1 shipped by
Debian 12 / Ubuntu 24.04.

## Options

```
./install.sh [--sidecar <url|path>] [--packages] [--tools] [--latex]
             [--macos-defaults] [-n]
```

- `--packages` — OS packages from `install/Brewfile` (macOS),
  `install/packages-apt.txt` (Debian/Ubuntu) or `install/packages-dnf.txt`
  (Fedora/RHEL).
- `--tools` — mise-managed tools (npm/uvx/github backends) plus gems, see
  `install/tools.sh`.
- `--latex` — latex helper packages via tlmgr.
- `--macos-defaults` — reviewed `defaults write` set, see `install/osx.sh`.
- `-n` — dry-run the linking step.

## Containers / throwaway VMs

```sh
apt-get update && apt-get install -y git stow zsh neovim   # or dnf equivalent
git clone <this-repo> ~/dots && ~/dots/dots link zsh git vim tmux bin
```

`dots link` with explicit package names skips the manifest selection — handy
when you only want a shell and editor in a container.

## After install

- Runtime managers self-bootstrap on first use: zi clones itself to
  `~/.zi/bin` on first zsh start (gitstatus fetches its own binary the same
  way); nvim bootstraps lazy.nvim and installs plugins pinned by the
  committed `lazy-lock.json` on first launch. tmux has no plugin manager —
  the few bindings that plugins provided are inlined in `.tmux.conf`.
- `chsh -s "$(command -v zsh)"` if zsh isn't the login shell (install.sh
  prints a reminder; it never runs chsh for you).
