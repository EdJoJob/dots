---
status: accepted
date: 2026-07-22
---

# Long-command phone notifications via ntfy

## Context and Problem Statement

The zsh theme pushed "long command finished" notifications to a phone via
the Join API (Android-only, key in a local file). The current phone is an
iPhone and Join is retired here; a replacement push channel was needed.

## Considered Options

- **[ntfy](https://ntfy.sh)** — chosen: open source, iOS app, topic-based
  pub/sub, no account required, self-hostable.
- Pushover — solid but paid, account-bound.
- Email/iMessage hacks — high friction, no CLI-first story.

## Decision Outcome

The theme's push branch posts to ntfy. Behaviour preserved from the Join
era: local notification at `LONG_CMD_NOTIFY_THRESHOLD` (30s), phone push
only beyond **3×** that (90s). Nothing fires when unconfigured.

- The **topic name is a capability secret** (anyone who knows it can spam
  the phone): it is read via `secret get ntfy-topic`
  (see [0005](0005-secrets-seed-once-into-os-keychain.md)), never hardcoded.
- `NTFY_SERVER` overrides the default ntfy.sh for a self-hosted instance;
  for a self-hosted server the access control is network reachability
  (tailnet-only interface) plus a bearer token when `ntfy-token` is seeded.

### Consequences

- Good: works on iOS/Android/desktop; degrades to silence when unset.
- Bad: public ntfy.sh topics are only as secret as the topic string —
  hence the capability-secret treatment.
