---
status: accepted
date: 2026-07-31
---

# iTerm2 tooling splits by whether iTerm2 runs on the machine or is merely reachable

## Context and Problem Statement

The machines you *use* iTerm2 from and the machines you *reach through* it are
mostly not the same machines. A dev container or VM has a shell driven from an
iTerm2 pane, but no iTerm2 app, no `osascript`, and no local API socket.

The capture toolchain ([0010](0010-iterm2-output-capture.md)) has parts on both
sides of that line. A single `iterm` package would either refuse to link on
those hosts or link Mac-only files where nothing can use them.

## Decision Drivers

- A remote host should get exactly the half it can run, decided by package
  membership rather than by runtime guards multiplying inside each script.
- The stow model links whole packages, so the boundary has to be a package
  boundary to mean anything.

## Considered Options

- **Two packages, split on "does iTerm2 run here"** — chosen.
- One `iterm` package with runtime guards — the guards multiply, and the
  Mac-only files still land on hosts that cannot use them.
- Putting the client half in `bin` alongside `extract-tokens` — rejected: `bin`
  is terminal-agnostic, and the client half is specifically an iTerm2 consumer.

## Decision Outcome

- **`iterm`** holds the "iTerm2 runs on this machine" half: the AutoLaunch
  scripts and `it2-cookie`. Both need the app present — `it2-cookie` reads the
  app's sdef and drives it via `osascript`.
- **`iterm-client`** holds the consumer half: `it2-last-output` and the fzf
  token widgets. These need only a *reachable* iTerm2 API, over a forwarded
  port if necessary.
- **`extract-tokens` stays in `bin`.** It parses text and knows nothing about
  terminals.

`manifests/darwin` makes both opt-in; `manifests/headless` links only
`iterm-client`, for containers and VMs.

### Consequences

- Good: remotes get the usable half and nothing else, enforced by package
  membership rather than by conditionals inside each script.
- Good: the parser is reusable outside this toolchain entirely.
- Bad, and this is the important half: **the client half cannot mint its own
  credentials.** `it2-last-output` stubs out the library's AppleScript cookie
  minting precisely because off-mac it dies with `FileNotFoundError` before the
  connection is even attempted. No app, no `osascript`, no local socket — so
  auth has to arrive from outside the client. That constraint is what
  [0012](0012-iterm2-api-auth-and-reusable-cookies.md) resolves; read it as the
  consequence of this split rather than as an unrelated problem.
- Bad: two packages to keep in step. A new file's home is decided by one
  question — does it need iTerm2 present, or only reachable?
