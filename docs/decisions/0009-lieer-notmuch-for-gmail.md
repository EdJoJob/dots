---
status: accepted
date: 2026-07-23
---

# Mail: lieer + notmuch as the Gmail path

## Context and Problem Statement

The mail stack was neomutt + offlineimap + davmail + notmuch, dormant but
wanted back. The blocking question for modernization: what does "moving a
message to a folder" mean against Gmail, where folders are labels?

## Decision Drivers

- Two-way label sync: a local "move" must become a Gmail label change.
- notmuch tags as the single local source of truth.
- Maintained tooling; no IMAP OAuth gymnastics for Gmail.

## Considered Options

- **lieer (`gmi`)** — chosen: talks the Gmail API directly, maps labels
  two-way onto notmuch tags, no All Mail duplication, faster than IMAP.
- offlineimap(3) — the only IMAP syncer with true label round-tripping
  (`synclabels` ↔ `X-Keywords:`), but maintenance-mode.
- mbsync/isync — actively maintained but has **no label concept**;
  multi-label messages duplicate locally and Gmail UIDVALIDITY quirks make
  moves fiddly.

## Decision Outcome

lieer + notmuch + neomutt vfolders (architecture and runbook in
[../MAIL.md](../MAIL.md)): `gmi` syncs `~/mail/<acct>`, notmuch indexes it,
neomutt opens saved notmuch queries as virtual mailboxes. A "move" is a
retag (`<modify-labels-then-hide>-inbox +receipts`), which the next sync
turns into a Gmail label move. Scheduling: systemd user timers
(`lieer-sync@`) on Linux, a launchd agent running `gmi-sync-all` on macOS.

The offlineimap/davmail configs stay in the tree as **legacy reference** —
still the path for non-Gmail/Exchange accounts.

### Consequences

- Good: labels ↔ tags with no folder fiction; resumable syncs; per-repo
  locks make overlapping runs safe.
- Bad: Gmail-only; migration is a full re-download (`gmi init` cannot
  adopt an existing maildir); lieer allows only one of inbox/spam/trash
  to stick and treats draft/sent as read-only locally.
