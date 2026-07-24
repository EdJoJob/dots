---
status: accepted
date: 2026-07-23
---

# Editor: Neovim-only — init.lua, lazy.nvim, native LSP

## Context and Problem Statement

The vim config claimed to support both vim and nvim, but already depended
on nvim-only features (lua heredocs, treesitter main-branch APIs) —
"works in vim" was fiction. It carried a dual completion/diagnostics stack
(coc.nvim **and** ALE), vendored vim-plug, and needed a node runtime for
coc.

## Decision Drivers

- One editor target; delete the dual-stack complexity.
- Keep the muscle-memory contract: `gd`/`gy` jump (multiple results →
  quickfix), `gr`/`gi` open fzf pickers, `K` keeps the vim-help carve-out,
  `<leader>rn`/`<leader>a`, Tab completion.
- Plugin versions must be pinned and reproducible across machines.

## Considered Options

- **nvim-only: init.lua + lazy.nvim + native LSP** — chosen.
- Keep vimscript + coc.nvim + vim-plug — status quo; node dependency,
  vendored plugin manager, two diagnostic systems.
- nvim-only but keep coc — halves the win; coc bundles its own servers.

## Decision Outcome

- Full **init.lua** config (`lua/config/*`, `lua/plugins/*`,
  `after/ftplugin/*.lua`).
- **lazy.nvim** with a repo-tracked `lazy-lock.json` (resolved through the
  init.lua symlink); `:Lazy restore` re-pins exactly.
- **Native LSP** replaces coc.nvim, preserving the interface contract
  above (`gr`/`gi` via fzf-lua, completion via nvim-cmp + UltiSnips,
  `if/af/ic/ac` via treesitter-textobjects). **ALE remains linters-only.**
- Server binaries come from the manifests, not the editor: gopls via
  Brewfile; pyright/typescript-language-server/yaml-language-server/
  vscode-langservers-extracted/vim-language-server via mise npm backends
  ([0006](0006-mise-first-tool-management.md)).
- nvim's built-in `gc` commenting replaces nerdcommenter, with
  `<leader>c<space>`/`<leader>cc`/`<leader>cu` mapped onto the toggle so the
  muscle memory keeps working; fzf is a lazy-managed plugin (no `~/.fzf`
  install).

### Consequences

- Good: one stack, pinned plugins, no node/coc; startup and maintenance
  drop.
- Bad: plain `vim` on remote boxes gets stock vim — nothing here deploys
  for it.
- Note: `~/.local_vimrc` now sources **after** plugins (it gets the last
  word on options/maps); `g:` vars that must precede plugin load belong in
  the repo config.
