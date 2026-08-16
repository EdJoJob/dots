---
status: accepted
date: 2026-08-16
---

# Snippets: LuaSnip replaces UltiSnips, and nvim drops the python3 provider

## Context and Problem Statement

[0008](0008-neovim-only-lazy-nvim-native-lsp.md) settled on nvim-only with
native LSP and named "completion via nvim-cmp + UltiSnips" as part of the
interface contract. UltiSnips is a vimscript plugin implemented in python, so
it requires nvim's python3 provider, which required a pynvim venv on every
machine. `install.sh` provisioned that venv at `~/.local/neovim`, and the
side-car container image installed `python3-neovim` toward the same end.

That machinery was carrying no weight. An audit of all 28 snippets in
`UltiSnips/{all,python,yaml}.snippets` found **no snippet using a single python
feature**: no `!p` interpolation block, no `global !p`, no `$VISUAL`, no `r`
regex trigger, no `e` context trigger, no `A` autotrigger. The only
interpolation anywhere was five `` `!v strftime(...)` `` vimscript evals in
`all.snippets`, and the only option flag in use was `w`. The python dependency
was an *engine* dependency, not a *feature* dependency.

It was not free. `plugin/UltiSnips.vim` runs an unconditional `py3 << EOF`
block at source time, booting the pynvim provider process before a key is
pressed, and there is no lazy path around it: UltiSnips cannot know whether it
has snippets for a filetype without python. Measured self time for that one
file was 78 ms in one profile and 117 ms in another, against total startups of
157 ms and 256 ms respectively. Roughly half the startup budget, once per
session.

The venv itself had also rotted: created by hand in March 2023, python 3.9.6
(EOL October 2025), pynvim 0.4.3, interpreter symlinked into Xcode
CommandLineTools. Functional, but reprovisioned per machine and pinned to an
interpreter that moves under Xcode updates.

## Decision Drivers

- Preserve the snippet corpus behaviour exactly. A migration that quietly
  changes what expands is worse than the venv.
- Preserve the keymap contract from [0008](0008-neovim-only-lazy-nvim-native-lsp.md):
  Tab completion, `<M-Space>` expand, `<c-b>`/`<c-k>` jump.
- Remove a per-machine provisioning step, not relocate it.

## Considered Options

- **LuaSnip, snippets hand-rewritten as lua** — chosen. In-process lua, no
  provider, no interpreter. Costs the plain-text `.snippets` format.
- Keep UltiSnips, manage the venv properly (uv-created venv at a fixed path,
  pynvim installed by `install.sh`) — makes the dependency tidy rather than
  absent, and keeps the ~78 ms startup cost permanently.
- LuaSnip, snippets converted to VSCode-style JSON via `from_vscode` — LSP
  snippet syntax has no evaluation construct, so the five date snippets cannot
  be expressed at all. Rejected.
- LuaSnip via `from_snipmate` — carries backtick eval, but drops per-snippet
  option flags. Viable for `all.snippets` only, wrong for the rest.
- Run both engines during a transition — nvim-cmp's `snippet.expand` is a
  single configured function, so only one engine can own LSP-snippet
  expansion. Workable, but the transitional `<Tab>` chain is more complexity
  than the whole rewrite for a 194-line corpus.

## Decision Outcome

Snippets live in `packages/vim/.config/nvim/luasnippets/{all,python,yaml}.lua`,
loaded by `require('luasnip.loaders.from_lua').lazy_load()`, one file per
filetype. `UltiSnips/` is deleted. `cmp_luasnip` replaces
`cmp-nvim-ultisnips` as the cmp source.

Feature mapping that mattered:

| UltiSnips | LuaSnip |
| --- | --- |
| `` `!v strftime(fmt)` `` | `extras.partial(os.date, fmt)`; lua's `os.date` wraps strftime, so format strings carry over |
| `w` flag | `wordTrig`, on by default. It rejects a trigger only when the preceding char is `[%w_]`, so the `.` in `s.date` is no obstacle |
| bare `$1` mirror | `extras.rep(1)` |
| `${N:$M}` | a dynamicNode, **not** `rep()` |

That last row was the only real work. `${2:$1}` is an editable tabstop
pre-filled from tabstop 1: you type the expression at 1, jump to 2, and shorten
the copy sitting there. `rep()` produces a frozen copy and would silently lose
the behaviour. The correct form is
`d(idx, function(args) return sn(nil, { i(1, args[1]) }) end, { ref })`, wrapped
as a local `label_of` helper since seven snippets use it. All seven reference
their argnode *forward* (the `${2:$1}` appears textually before `${1:...}`),
which upstream docs neither document nor exemplify; verified working, because
argnode resolution is by position in the node tree rather than textual order.

Indentation is written into the snippet bodies as literal spaces (4 for python,
2 for yaml), matching what UltiSnips produced from tabs under each ftplugin's
`expandtab`/`shiftwidth`. LuaSnip adds the indent of the expansion point on top
of that, verified as additive rather than doubled.

**The python3 provider is disabled outright**: `lua/config/options.lua` sets
`vim.g.loaded_python3_provider = 0` in place of the old `python3_host_prog`, so
nvim does not even probe for an interpreter. `install.sh` no longer creates
`~/.local/neovim`, and `python3-neovim` is gone from the container image. The
only other python-adjacent mapping in the config, `<space>i` for isort
(`after/ftplugin/python/python.vim`), shells out to the binary (`:%!isort -`)
and is unaffected.

One keymap behaviour needed spelling out. Under UltiSnips, `<c-b>` served both
docs-scroll and snippet jump-forward, and the jump won while a snippet was
active only because UltiSnips installed a **buffer-local** map. LuaSnip's
keymaps are global, so a standalone `ls.jump(1)` on `<c-b>` would shadow
docs-scroll unconditionally. The precedence is therefore explicit in the cmp
mapping, gated on `ls.locally_jumpable(1)` (`in_snippet() and jumpable(dir)`),
which reproduces the old semantics. `<c-k>` is gated the same way.

Two snippets were fixed rather than ported verbatim, both broken before this
change and independent of engine:

- `loge` emitted `try:` immediately followed by `except:`, a `SyntaxError`. The
  body is now an `i(1, 'pass')` tabstop.
- `err` used python 2 `print >>sys.stderr`, and had a one-character typo,
  `{$2:$1}` for `${2:$1}`, which cost it the copy-then-edit label its siblings
  have. It expanded to the literal `{:locals()}`.

### Consequences

- Good: no python3 provider, no pynvim, no venv, no `python3-neovim` package,
  no provisioning step in `install.sh`. The dependency is absent rather than
  managed.
- Good: startup measured at 89-92 ms across three runs, against 157-256 ms
  before. `UltiSnips` appears nowhere in the profile.
- Good: LuaSnip's node model is strictly more capable where it matters here
  (choiceNodes, dynamicNodes, `condition`/`show_condition`, `priority`,
  `filetype_extend`), and snippet files now get LSP and treesitter, since they
  are lua.
- Good: escaping gets easier. `{` is special after `$` in UltiSnips, which the
  jinja-heavy yaml snippets had to work around; in a lua string a brace is a
  brace.
- Bad: adding a throwaway snippet means writing a function call rather than
  three lines of plain text. This is the genuine cost of the migration, and it
  is ergonomic, not functional.
- Bad: no `.snippets` syntax file and no `iS`/`aS` snippet text objects.
- Neutral: `:UltiSnipsEdit` maps onto `require('luasnip.loaders').edit_snippet_files()`,
  whose `edit` callback covers the old `UltiSnipsEditSplit = 'context'`. The
  flow differs: UltiSnips opened the current filetype's file directly, LuaSnip
  presents a `vim.ui.select` picker first, which fzf-lua already handles.
- Note: `yaml.snippets`' `debug-local` indented `module:`/`content:`/`dest:` as
  siblings of `local_action:` rather than its children, which is probably not
  the Ansible task it means to describe. Carried over verbatim, since fixing it
  is a guess at intent.

Supersedes the "nvim-cmp + UltiSnips" clause of
[0008](0008-neovim-only-lazy-nvim-native-lsp.md); everything else in that
record stands, and the interface contract it lists is unchanged.
