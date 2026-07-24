#!/bin/bash
# Tool layer. Language-ecosystem CLI tools all flow through mise from the
# packaged ~/.config/mise/config.toml (npm/uvx/ubi backends) so identical
# things land identically on macOS/Debian/RedHat. OS packages are reserved
# for C-linked system tools. Run after `dots link` (the config must be stowed).
set -euo pipefail

# mise itself: brew on macOS; official self-install elsewhere (no distro pkg)
if ! command -v mise >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install mise
    else
        curl -fsSL https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

mise install || echo "warning: some mise tools failed to install; re-run install/tools.sh"

# ruby gem odd-one-out (no mise backend in use for gems)
if command -v gem >/dev/null 2>&1; then
    if ! gem list -i github-auth >/dev/null 2>&1; then
        gem install --user-install github-auth || echo "warning: gem install github-auth failed; continuing"
    fi
else
    echo "gem not found; skipping github-auth"
fi
