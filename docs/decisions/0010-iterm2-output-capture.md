---
status: accepted
date: 2026-07-31
---

# Recent terminal output is captured over the iTerm2 Python API

## Context and Problem Statement

Working in a terminal, the values worth reusing are already on screen —
service ids, node names, uuids, hostnames printed by the last command. Getting
them into the *next* command line meant reaching for the mouse, or retyping
them by eye. The need is to pick a token out of recent output and insert it at
the cursor, without leaving the keyboard.

Two constraints made the obvious answers insufficient: the shell is often
reached over ssh from the terminal doing the displaying, and it frequently runs
under `tmux -CC`, whose control-mode relay breaks assumptions that hold for a
normal client.

## Considered Options

- **The iTerm2 Python API** — chosen. iTerm2 already holds the scrollback and
  the shell-integration prompt marks, and exposes both over a local socket that
  an ssh session can reach through a forwarded port.
- tmux copy-mode plus extrakto — requires tmux for a capability that should not,
  and under `tmux -CC` the pane bytes are relayed rather than rendered, so the
  assumptions extrakto relies on do not hold.
- Tee-ing shell output to a file — captures everything including what the pane
  never showed, loses the pane's own rendering and any notion of "the last
  command", and grows without bound.

## Decision Outcome

Three parts, split so that each has one job:

- **capture** (`it2-last-output`) asks iTerm2 for a line range and prints it.
- **parse** (`extract-tokens`) turns text into `value <TAB> label <TAB> context`
  TSV. Deliberately terminal-agnostic and iTerm2-agnostic — it reads stdin, so
  it is useful on any output from anywhere.
- **bind** (`.zsh_iterm_fzf`) wires the pair to `^X^S` and `^X^A` as zle widgets
  and inserts the selection at the cursor.

Which *package* each part ships in is a separate decision — see
[0011](0011-iterm-client-package-split.md). Auth is
[0012](0012-iterm2-api-auth-and-reusable-cookies.md).

Two mechanisms are load-bearing and non-obvious:

**The capture script is a single file with an `sh` bootstrap** that builds a
`uv` venv on first run, then `exec`s the venv's python on itself. Deliberately
*not* `uv run --script`: uv (through 0.11.32) does not exit after its child
reads a raw-mode `/dev/tty` reply, which wedges every invocation that performs
the tty query below. The bootstrap gates on importing the dependency rather
than on the interpreter existing, because an install that dies partway leaves a
usable-looking venv; and it guards venv creation separately from the install,
because `uv venv` is not idempotent.

**Session resolution is a ladder, and it fails loudly rather than guessing.**
`ITERM_SESSION_ID` when set — but never inside tmux, where it names whatever
pane the server inherited it from. Otherwise a per-pane cache. Otherwise ask
the terminal itself over the tty (OSC 1337 ReportVariable, which crosses both
ssh and `tmux -CC`). Outside tmux, a last resort takes the frontmost window's
active session; inside tmux that would silently target whichever window was
clicked last, so it errors instead.

### Consequences

- Good: works over ssh and under `tmux -CC`, and reuses the prompt marks
  shell integration already sets, so "the last command's output" is a real
  range rather than a guess.
- Good: the parser is independent of the capture mechanism and of iTerm2.
- Bad: depends on the iTerm2 Python API being enabled, and carries a venv.
- Bad: the OSC query is a tty read, so nothing else may read the tty
  concurrently. A widget must run the producer to completion *before* starting
  fzf; as the head of a pipeline into fzf, both read the tty and whichever wins
  takes the reply — the query times out with nothing to show while the reply
  lands in fzf's search box as typed garbage. The reproduction lives in the
  commit that introduced the sequencing.
- Bad: the API's line coordinates are absolute and overflow-inclusive, which is
  easy to get wrong invisibly — the error cancels on any pane that has not
  filled its scrollback. The contract is stated in the capture script's window
  helpers and pinned by `tests/test_it2_windows.py`.
