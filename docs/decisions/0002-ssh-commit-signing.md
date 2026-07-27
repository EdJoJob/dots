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
`gpg.ssh.allowedSignersFile`. Signing is enabled **per repo** by the
identity aliases in `.aliases.zsh` — `personal_repo` / `work_repo` set
`user.email`, `user.name`, `user.signingkey` to the matching public key
under `~/.ssh/github/*.pub`, and `commit.gpgsign = true` in one move.
Only `.pub` files exist on disk; the private keys live in the 1Password
ssh-agent, which git drives automatically when the signingkey is a
public-key path (`ssh-keygen -Y sign -U`).

Per-repo rather than global `gpgsign` because the same reason the aliases
exist applies to signing: work and personal repos need different
identities, and a global default silently signs with the wrong one.

The `ssh-allowed_signer` zsh helper appends the current repo's identity to
`~/.ssh/allowed_signers` (side-car-owned) so `git log --show-signature`
verifies locally. Smoke test: `git commit --allow-empty -m sign-test &&
git log -1 --show-signature`. A GPG key remains useful only for
decrypting old material, not for signing.

### Consequences

- Good: one key agent (1Password) for auth and signing; no expiry cliffs;
  identity and key always move together.
- Bad: repos where no identity alias was run don't sign at all;
  verification needs an allowed-signers file per machine, and GitHub shows
  "verified" only after the key is registered as a signing key.
