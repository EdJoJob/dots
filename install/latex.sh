#!/bin/bash
# Opt-in latex setup; requires a TeX distribution (e.g. basictex) already installed.
set -e

if ! command -v tlmgr >/dev/null 2>&1; then
    echo "tlmgr not found; skipping latex setup"
    exit 0
fi

SUDO="sudo"
[ "$(id -u)" -eq 0 ] && SUDO=""

# Distro-packaged TeXLive (apt/dnf texlive) ships a tlmgr that cannot
# self-update; treat that as "managed elsewhere" and bail politely.
if ! $SUDO tlmgr update --self 2>/dev/null; then
    echo "tlmgr cannot self-update (distro-managed TeXLive?) — skipping latex setup"
    exit 0
fi
$SUDO tlmgr update --all
$SUDO tlmgr install texliveonfly
