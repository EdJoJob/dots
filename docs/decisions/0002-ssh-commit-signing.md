---
status: accepted
date: 2026-07-22
---

# Sign git commits with SSH keys, not GPG

## Context and Problem Statement

Commit signing used a personal GPG key, which has expired; renewing means
staying on the GPG toolchain (agent, pinentry, expiries) for the single
purpose of git signatures.

## Considered Options

- **SSH signing (`gpg.format = ssh`)** — chosen.
- Renew/replace the GPG key — keeps working, keeps the toolchain burden.

## Decision Outcome

Tracked `.gitconfig` sets `gpg.format = ssh` and
`gpg.ssh.allowedSignersFile`. Everything key-bearing is side-car material
(`~/.local_gitconfig`):

```ini
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
[user]
    signingkey = key::ssh-ed25519 AAAA... comment
[commit]
    gpgsign = true
```

The `key::` form needs no key file on disk (1Password holds the key and
signs). The `ssh-allowed_signer` zsh helper appends the public key to
`~/.ssh/allowed_signers` so `git log --show-signature` verifies locally.
Smoke test: `git commit --allow-empty -m sign-test && git log -1
--show-signature`. A GPG key remains useful only for decrypting old
material, not for signing.

### Consequences

- Good: one key agent (1Password/ssh-agent) for auth and signing; no
  expiry cliffs.
- Bad: signature verification needs an allowed-signers file per machine;
  GitHub shows "verified" only after the key is registered as a signing key.
