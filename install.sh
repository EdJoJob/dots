#!/usr/bin/env bash
# Bootstrap this dotfiles repo on a fresh machine.
#
#   git clone <this-repo> ~/dots && cd ~/dots && ./install.sh [options]
#
# Options:
#   --sidecar <url|path>   clone/scaffold the private side-car repo first
#   --packages             install OS packages (Brewfile / apt / dnf manifests)
#   --tools                install mise-managed tools (npm/uvx/github backends) + gems
#   --latex                install latex helpers (needs tlmgr)
#   --macos-defaults       apply install/osx.sh defaults (macOS only)
#   -n | --dry-run         show what `dots link` would do without doing it
#
# The only hard prerequisites are git and a shell. GNU Stow (and zsh, if
# missing) are installed via the platform package manager.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

info() { printf 'install: %s\n' "$*"; }
die()  { printf 'install: error: %s\n' "$*" >&2; exit 1; }

SIDECAR_URL=""
DO_PACKAGES=0 DO_TOOLS=0 DO_LATEX=0 DO_DEFAULTS=0 DRY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --sidecar) shift; [ $# -gt 0 ] || die "--sidecar needs a url or path"; SIDECAR_URL=$1 ;;
        --packages) DO_PACKAGES=1 ;;
        --tools) DO_TOOLS=1 ;;
        --latex) DO_LATEX=1 ;;
        --macos-defaults) DO_DEFAULTS=1 ;;
        -n|--dry-run) DRY="-n" ;;
        -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option '$1' (see --help)" ;;
    esac
    shift
done

# --- base dependencies -------------------------------------------------------

# Root (containers, kickstarts) needs no sudo.
SUDO="sudo"
[ "$(id -u)" -eq 0 ] && SUDO=""

need_pkgs=""
command -v stow >/dev/null 2>&1 || need_pkgs="stow"
command -v zsh  >/dev/null 2>&1 || need_pkgs="$need_pkgs zsh"

if [ -n "$need_pkgs" ]; then
    info "installing base dependencies:$need_pkgs"
    if command -v brew >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        brew install $need_pkgs
    elif command -v apt-get >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        $SUDO apt-get update -qq && $SUDO apt-get install -y $need_pkgs
    elif command -v dnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        $SUDO dnf install -y $need_pkgs ||
            die "dnf failed — on RHEL, stow lives in EPEL: $SUDO dnf install epel-release, then re-run"
    elif [ "$(uname -s)" = "Darwin" ]; then
        die "Homebrew is required on macOS: https://brew.sh (then re-run)"
    else
        die "no supported package manager found (brew/apt-get/dnf) — install manually:$need_pkgs"
    fi
fi

# --- side-car ----------------------------------------------------------------

if [ -n "$SIDECAR_URL" ]; then
    if [ -n "$DRY" ]; then
        info "[dry-run] would run: ./dots sidecar-init $SIDECAR_URL"
    else
        ./dots sidecar-init "$SIDECAR_URL"
    fi
fi

# --- symlink deployment ------------------------------------------------------

info "deploying symlinks (dots link $DRY)"
./dots link $DRY

# --- nvim python provider ------------------------------------------------------
# UltiSnips (and anything else using the python3 provider) reads
# g:python3_host_prog = ~/.local/neovim/bin/python3 — provision that venv.

if [ -z "$DRY" ] && command -v python3 >/dev/null 2>&1; then
    NVIM_VENV="$HOME/.local/neovim"
    if [ ! -x "$NVIM_VENV/bin/python3" ]; then
        info "creating nvim python provider venv at ~/.local/neovim"
        python3 -m venv "$NVIM_VENV" ||
            info "venv creation failed (Debian/Ubuntu: apt install python3-venv) — nvim python plugins will be inert"
    fi
    if [ -x "$NVIM_VENV/bin/python3" ] && ! "$NVIM_VENV/bin/python3" -c 'import pynvim' 2>/dev/null; then
        info "installing pynvim into the provider venv"
        "$NVIM_VENV/bin/python3" -m pip install --quiet --upgrade pip pynvim ||
            info "pynvim install failed (non-fatal); re-run install.sh to retry"
    fi
fi

# --- terminfo ----------------------------------------------------------------

if [ -z "$DRY" ] && command -v tic >/dev/null 2>&1; then
    if ! infocmp tmux-256color >/dev/null 2>&1; then
        info "compiling tmux-256color terminfo"
        tic -x install/tmux-256color.terminfo || info "terminfo compile failed (non-fatal)"
    fi
fi

# --- optional layers ---------------------------------------------------------

run_layer() {  # $1... = command; skipped with a message under --dry-run
    if [ -n "$DRY" ]; then
        info "[dry-run] would run: $*"
    else
        "$@"
    fi
}

if [ "$DO_PACKAGES" -eq 1 ]; then
    # packages.sh has its own preview mode — use it under -n
    if [ -n "$DRY" ]; then ./install/packages.sh --dry-run; else ./install/packages.sh; fi
fi
[ "$DO_TOOLS" -eq 1 ]    && run_layer ./install/tools.sh
[ "$DO_LATEX" -eq 1 ]    && run_layer ./install/latex.sh
if [ "$DO_DEFAULTS" -eq 1 ]; then
    [ "$(uname -s)" = "Darwin" ] || die "--macos-defaults only makes sense on macOS"
    run_layer ./install/osx.sh
fi

if [ "$(uname -s)" = "Linux" ] && [ -z "$DRY" ] && command -v systemctl >/dev/null 2>&1; then
    info "systemd user units are linked but NOT enabled — pick what this machine runs, e.g.:"
    info "    systemctl --user daemon-reload"
    info "    systemctl --user enable --now greenclip.service vdirsyncer.timer"
fi
if [ "$(uname -s)" = "Darwin" ] && [ -z "$DRY" ] &&
   [ -e "$HOME/Library/LaunchAgents/com.edjojob.gmi-sync.plist" ]; then
    info "mail launchd agent is linked but NOT loaded — load it with:"
    info "    launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.edjojob.gmi-sync.plist"
fi

# --- wrap up -------------------------------------------------------------------

./dots doctor || true

case "${SHELL:-}" in
    */zsh) ;;
    *) info "zsh is not your login shell — run: chsh -s \"\$(command -v zsh)\"" ;;
esac
info "done."
