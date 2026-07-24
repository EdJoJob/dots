# Managing the dotfiles

Deployment is GNU Stow driven by `./dots` (also on PATH as `~/.bin/dots` once
linked). Two source repos, one flow:

- **main repo** (`~/dots`, this one — public): shared config.
- **side-car** (`~/src/local-dots` by default — private): per-machine and
  per-identity config. Override location with `DOTS_SIDECAR` or
  `~/.config/dots/sidecar`.

## Concepts

- A **package** is a directory under `packages/` whose contents mirror `$HOME`
  literally: `packages/zsh/.zshrc` deploys to `~/.zshrc`.
- **Manifests** (`manifests/common` + `manifests/darwin|linux`) pick which
  packages deploy on this machine. No manifests dir → all packages.
- Stow always runs `--no-folding`: real directories are created and each file
  is linked individually. Both repos can therefore own different files under
  the same directory (`~/.config`, `~/.bin`, …), and nothing an application
  writes next to your links ever lands inside a repo.
- **Conflicts are hard errors.** A real file in the way, or both repos
  claiming the same path — `dots link` aborts before touching anything and
  lists the offenders. That's by design; resolve, then re-run.

## Day-to-day

```sh
dots link                # deploy everything selected by the manifests
dots link vim            # just one package
dots relink              # after adding/removing files in a package
dots unlink mail         # remove a package's links
dots list                # per-file state: linked / unlinked / CONFLICT
dots doctor              # full diagnosis, incl. broken and pre-migration links
```

### Adding a brand-new config file

Put it at its literal path inside a package and relink:

```sh
vi packages/zsh/.zsh_something
dots relink zsh
```

### Adopting an existing file ("get this under management")

```sh
dots adopt ~/.config/foo/config.toml       # package inferred — only when one package already tracks the dir; new dirs need -p
dots adopt -p zsh ~/.zprofile              # explicit package
dots adopt -s -p core ~/.local_something   # -s = into the private side-car
```

`adopt` moves the file into the repo, `git add`s it, and restows so a symlink
replaces it. It refuses to run if the target package has uncommitted changes,
so every adoption is a clean reviewable diff.

**Warning — the default target is the PUBLIC repo.** A forgotten `-s` on a
file holding a token puts the credential into public git history. Nothing
scans content on adopt; the diff review IS the control. If the file could
possibly contain a secret, it belongs in the side-car (`-s`) — when unsure,
grep it first.

### Machine-specific config

The tracked configs source these local files, all guarded — absence is fine:

| File | Sourced by | Belongs in |
|---|---|---|
| `~/.local_zshrc` | `.zshrc` (early) | side-car `core` |
| `~/.local_gitconfig` | `.gitconfig` include | side-car `core` |
| `~/.local_tmux.conf` | `.tmux.conf` (`-q`) | side-car `core` |
| `~/.local_vimrc` | `init.lua` (guarded, after plugins) | side-car `core` |
| `~/.local_muttrc` | `.muttrc` | side-car `mail` |
| `~/.ssh/config.d/*` | ssh `Include` | side-car `ssh` |

Rule of thumb: identity, hosts, tokens (via `secret get`), employer-specific
anything → side-car. Everything else → main repo.

### Opt-in packages

Not in any manifest; link explicitly where wanted:

```sh
dots link mail     # neomutt + lieer/notmuch vfolders (legacy offlineimap for non-Gmail; see docs/MAIL.md)
dots link gnupg    # gpg.conf / gpg-agent.conf into existing ~/.gnupg
dots link iterm    # iTerm2 AutoLaunch scripts (macOS)
```

To make one permanent on a machine, add its name to that machine's side-car
`manifests/common` — manifests select packages across both repos by name.

## Secrets

The rule: **`op read` never runs at use-time** — it costs seconds and needs a
TTY. Instead, seed once and read from the OS keychain:

```sh
secret seed            # op read every ~/.config/dots/secrets.map entry -> keychain
secret get <name>      # runtime read: ~30ms, no TTY, daemon-safe while logged in
secret ls              # map entries and their seeded/MISSING state
```

The map (side-car `core` package) holds only *references* (`name op://ref`),
never values. Rotation = rotate in 1Password, re-run `secret seed`.

The tradeoff to know: the same ACL property that makes reads prompt-free
means **any process running as your logged-in user can silently read every
seeded secret**. That's the accepted cost of daemon-safe access (vs. op's
per-use prompting) — keep genuinely high-blast-radius credentials in
1Password only, and seed just what services actually consume.

### Headless containers and VMs (hermit etc.)

No keychain, no op GUI inside. Options, preferred first:

1. **Render at provision time** — the host has keychain access, so the
   container build/refresh step writes what's needed into the mounted
   container-local file (`secret get x >> container-local-zshrc` style,
   mode 600). Rotation = re-provision. This fits hermit's existing
   `~/.aiven/container-*` mounts.
2. **Env injection at launch** — `docker run -e X="$(secret get x)"`;
   nothing on disk, but visible in `docker inspect`/procfs.
3. **Host secrets broker** — bind-mount a unix socket served by a host
   process that answers `get <name>` from the keychain. Live rotation, most
   moving parts; only worth it if containers are long-lived and secrets
   rotate often.
4. **1Password service account** — `OP_SERVICE_ACCOUNT_TOKEN` makes `op`
   work headlessly, but every read is a network call and the token itself
   still needs injecting; right for CI, heavy for local containers.

### ntfy: the topic name IS the secret

On the public ntfy.sh server, anyone who knows a topic name can subscribe
*and* publish to it — a capability URL. So the topic never goes in ANY repo
(public or side-car): it lives in 1Password, seeds into the keychain, and the
zsh theme resolves it via `secret get ntfy-topic` (or `$NTFY_TOPIC` injected
into containers per the options above). Use a long random name and rotating
it is free.

#### Migrating to self-hosted ntfy later (planned)

The shell side is already wired — the switch is config-only:

Access control is the tailnet: thoth has no public interface, so reachability
IS the auth boundary — no ntfy tokens needed (the zsh push still attaches a
bearer automatically if an `ntfy-token` is ever seeded, as optional
defence-in-depth).

1. On thoth (Synology Docker): run `binwiederhier/ntfy serve` with volumes
   for `/etc/ntfy` and `/var/lib/ntfy`, listening only on the tailnet —
   simplest is `tailscale serve` fronting the container port, which also
   gives a real TLS cert at `https://thoth.<tailnet>.ts.net`.
2. `server.yml`: `base-url: https://thoth.<tailnet>.ts.net` and
   `upstream-base-url: https://ntfy.sh`  ← required for iOS push (APNS gets
   only a wake-up poke; message content stays on thoth).
3. Point clients at it: `NTFY_SERVER=https://thoth.<tailnet>.ts.net`; in the
   iOS app add the server per-subscription (Tailscale iOS app installed and
   connected).
4. iOS caveat to know: the wake-up poke arrives via APNS regardless, but the
   app fetches the message content FROM thoth — the phone must be on the
   tailnet at fetch time or the notification shows without its body.
5. Topic names stop mattering behind the tailnet — keep the old one or pick
   a readable one.

## Updating stow

Stow is a plain package everywhere (`brew upgrade stow`, `apt-get
install --only-upgrade stow`, `dnf upgrade stow`). Nothing in this repo pins
it; `dots doctor` prints the active version.

## Troubleshooting

- **`existing target is not owned by stow`** — a real file or foreign symlink
  sits where a link should go. `dots list` shows which. Adopt it, move it, or
  delete it.
- **`existing target is stowed to a different package`** — both repos claim
  the path; `dots link`'s pre-flight normally catches this first and names the
  duplicates. Remove the file from one repo.
- **Pre-migration links** (from the old `*.symlink` layout) — `dots doctor`
  lists them; `dots migrate-legacy` removes exactly those, then `dots link`.
