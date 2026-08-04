---
status: accepted
date: 2026-07-31
---

# iTerm2 API auth runs on the allow-all override today, with reusable cookies as the target

## Context and Problem Statement

The iTerm2 Python API needs authentication, and per
[0011](0011-iterm-client-package-split.md) the half that needs it most is the
half that cannot produce it: a container or VM has no iTerm2 app to ask. Over
ssh there is no local socket either, so the connection arrives through a
forwarded port.

Plain `request cookie` mints a **single-use** cookie — the first connection
consumes it and every later one gets 401 — which is useless for a tool invoked
once per keystroke. iTerm2's `disable-automation-auth` override ("Allow all apps
to connect") sidesteps auth entirely, but machine-wide and bluntly.

This ADR exists because the code implementing the upgrade path was misread as
dead during review and nearly deleted. The intent was legible only to whoever
wrote it; recording it is what makes carrying dormant code defensible.

## Considered Options

- **The "Allow all apps to connect" override** — chosen for now. Blunt and
  machine-wide, but the only thing that works on the 3.6.x series.
- **Reusable cookies** (`request cookie ... with reusable`) — chosen as the
  target, pending an iTerm2 that exposes them. Carried capability-gated so the
  upgrade is a version bump rather than a rewrite.
- Minting a fresh single-use cookie per invocation — defeated by the per-call
  AppleScript cost, and it dies off-mac before connecting at all.

## Decision Outcome

Run on the override today. Carry the reusable path behind capability detection,
and keep the failure mode *loud*: detection is scoped to the `request cookie`
command's own sdef block, distinguishes unsupported from unreadable, and
`it2-cookie --check` reports what it actually found. Dormant code that gates
itself on an unverified string otherwise fails closed and silent, which is
indistinguishable from "not upgraded yet".

**The attribute spelling is unverified.** The installed iTerm2 is 3.6.11, whose
sdef exposes `request cookie` with exactly one parameter,
`and key for app named`. Reusable cookies are expected in the 3.7.0 beta series.
No beta was available to inspect, so neither the parameter name nor the
AppleScript at the mint site has ever executed. `--check` exists so that is a
one-command diagnosis rather than silence.

### Activation checklist

When iTerm2 >= 3.7.0beta is installed:

1. Run `it2-cookie --check`. Confirm the verdict flips to supported.
2. If it does not, the spelling differs: read the `request cookie` parameters
   `--check` printed and update the detection to match.
3. Verify the AppleScript at the mint site actually executes — it never has.
   `--check` prints the session id that would be sent; confirm it is the bare
   id, with no `w0t0p0:` prefix.
4. Confirm the minted cookie survives a *second* connection. If it does not, it
   was single-use and the parameter was silently ignored.
5. Only then unwind the override: untick "Allow all apps to connect" and remove
   `disable-automation-auth`.
6. Export the cookie for ssh (`SendEnv ITERM2_COOKIE`, with sshd `AcceptEnv`),
   so the client half on remotes receives it.

### Consequences

- Good: the upgrade is a version bump plus a checklist, and the intent survives
  its author — it did not, once.
- Good: `--check` works today and reports the true state, so the gate can be
  tested before a beta exists.
- Bad: the override is machine-wide while it stands — any local process can
  drive the API.
- Bad: dormant code carries a reading tax. Review misjudged it once already,
  which is the cost this record is paying down.
- Bad: the cookie travels to remotes in the environment, readable by other
  processes of the same user on that host.
- Unwinding the override depends on a human running the checklist. The only
  prompt is `--startup`'s nag, which is itself gated on the same unverified
  detection — so step 1 is the real trigger.
