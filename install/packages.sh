#!/bin/bash
# System package installer — dispatches to brew / apt-get / dnf using the
# manifests next to this script. Language tooling lives in install/tools.sh.
#
# Usage: packages.sh [--dry-run]
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
fi

# Running as root (containers, kickstarts) needs no sudo; otherwise require it.
SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif ! command -v sudo >/dev/null 2>&1; then
    echo "packages.sh: not root and no sudo available" >&2
    exit 1
fi

# Strip comments (whole-line and trailing) and blank lines from a manifest
manifest_packages() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$'
}

# Batch install, then retry stragglers one-by-one so a package that is absent
# on this release (eza on Debian 12, Fedora-only entries on RHEL, ...) doesn't
# sink the whole transaction. Failures are reported, not fatal.
install_best_effort() {   # $1 = "cmd prefix", stdin = package list
    local cmd=$1 failed="" pkg
    local pkgs
    pkgs=$(cat)
    # shellcheck disable=SC2086
    if $SUDO $cmd $pkgs >/dev/null 2>&1; then
        echo "installed: $(echo "$pkgs" | tr '\n' ' ')"
        return 0
    fi
    echo "batch install incomplete — retrying per package"
    while IFS= read -r pkg; do
        # shellcheck disable=SC2086
        $SUDO $cmd "$pkg" || failed="$failed $pkg"
    done <<< "$pkgs"
    if [ -n "$failed" ]; then
        echo "packages.sh: unavailable on this release (skipped):$failed" >&2
    fi
}

if command -v brew >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "would run: brew bundle --file $INSTALL_DIR/Brewfile"
    else
        brew bundle --file "$INSTALL_DIR/Brewfile"
    fi
elif command -v apt-get >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "would run: $SUDO apt-get install -y \\"
        manifest_packages "$INSTALL_DIR/packages-apt.txt"
    else
        $SUDO apt-get update
        manifest_packages "$INSTALL_DIR/packages-apt.txt" |
            install_best_effort "apt-get install -y"
    fi
elif command -v dnf >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "would run: $SUDO dnf install -y \\"
        manifest_packages "$INSTALL_DIR/packages-dnf.txt"
    else
        # dnf is strict by default; tolerate per-distro gaps (Fedora-only
        # entries on RHEL). dnf5 spells it --skip-unavailable, dnf4 needs
        # strict=0; fall back to the per-package loop when neither works.
        pkgs=$(manifest_packages "$INSTALL_DIR/packages-dnf.txt")
        # shellcheck disable=SC2086
        if ! $SUDO dnf install -y --skip-unavailable $pkgs 2>/dev/null &&
           ! $SUDO dnf install -y --setopt=strict=0 $pkgs 2>/dev/null; then
            printf '%s\n' "$pkgs" | install_best_effort "dnf install -y"
        fi
    fi
else
    echo "No supported package manager found (brew, apt-get, dnf)" >&2
    exit 1
fi
