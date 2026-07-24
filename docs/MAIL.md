# Mail

Gmail via lieer + notmuch + neomutt. Legacy IMAP paths (offlineimap,
davmail) are kept as reference only — see the end.

## Architecture

```
Gmail (labels)  <--gmi sync-->  ~/mail/<acct>/   (maildir, one dir per account)
                                      |
                                notmuch index    (labels <-> tags, db at ~/mail)
                                      |
                                neomutt vfolders (virtual-mailboxes = saved
                                                  notmuch queries, used as
                                                  folder analogues)
```

- **lieer (`gmi`)** talks to the Gmail API (no IMAP): pulls mail and label
  changes into `~/mail/<acct>/`, pushes local tag changes back as label
  changes. Two-way, labels <-> notmuch tags.
- **notmuch** indexes everything under `~/mail`. Tags are the single source
  of truth locally.
- **neomutt** opens notmuch queries as virtual mailboxes. One label per
  message + per-account `path:` scoping makes vfolders behave like folders.
- **Scheduling** is per-platform (see below): systemd user timers on Linux,
  a launchd agent on macOS — both every ~5 minutes.

## Scheduling

### Linux (systemd user units)

Per-account template units, enabled individually:

```sh
systemctl --user daemon-reload
systemctl --user enable --now lieer-sync@<acct>.timer
```

Every 5 minutes (randomized +/-1m), `Type=oneshot`, skipped cleanly when the
account dir doesn't exist.

### macOS (launchd agent)

launchd has no template units, so one agent runs `~/.bin/gmi-sync-all`, which
syncs **every** dir under `~/mail` holding a `.gmailieer.json` (gmi's own
per-repo lock makes overlap safe). The plist is stowed to
`~/Library/LaunchAgents/com.edjojob.gmi-sync.plist`; loading is manual and
one-time:

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.edjojob.gmi-sync.plist
launchctl print gui/$(id -u)/com.edjojob.gmi-sync        # status
launchctl kickstart -k gui/$(id -u)/com.edjojob.gmi-sync  # run now
launchctl bootout gui/$(id -u)/com.edjojob.gmi-sync       # remove
```

It runs at login and every 5 minutes after; output goes to
`~/Library/Logs/gmi-sync.log`. Caveat: some macOS releases refuse to
`bootstrap` a *symlinked* plist — if you hit that, replace the link with a
copy (`rm` the link, `cp` from `packages/mail/Library/LaunchAgents/`;
`dots list` will then report a CONFLICT for that one path, which is expected
and can be ignored, or keep the copy outside stow's view).
`gmi-sync-all` also works on Linux if a single sync-everything timer is
preferred over per-account units.

## Fresh setup

1. Packages: `notmuch` (brew/apt/dnf) and lieer — installed via mise+uvx on
   every platform (`pipx:lieer` in the packaged mise config;
   `install/tools.sh` / `mise install`).
2. `~/.notmuch-config` from
   `templates/local-dots/packages/mail/.notmuch-config`
   (database at `~/mail`, `maildir.synchronize_flags=true`, lieer's
   `new.ignore` pattern for its `.json`/`.lock`/`.bak` state files).
3. `mkdir -p ~/mail && notmuch new` (lieer needs the db to exist).
4. Per account: `mkdir -p ~/mail/<acct> && cd ~/mail/<acct> &&
   gmi init <acct>@gmail.com && gmi sync`. OAuth details and the shared
   client-id caveat: `templates/local-dots/packages/mail/README-lieer.md`.
5. Schedule the sync (see "Scheduling" above for your platform).
6. neomutt: `~/.muttrc` already sets `nm_default_url` and
   `virtual_spoolfile` (guarded by `ifdef notmuch`, so non-notmuch builds
   are unaffected). Add per-account `virtual-mailboxes`, F-key
   `<change-vfolder>` macros and move-to-label macros to `~/.local_muttrc`
   — commented examples in
   `templates/local-dots/packages/mail/.local_muttrc`, including
   `set my_skip_maildir_startup = yes` to start in the first vfolder.

## "Moving to a folder"

There are no folders — a move is a retag. The move macro pattern:

```
<modify-labels-then-hide>-inbox +receipts<enter><sync-mailbox>
```

removes `inbox`, adds `receipts`, hides the message from the current
vfolder, and syncs. The next `gmi push` (part of every `gmi sync`) turns
that into "remove label INBOX, add label receipts" on Gmail. With the
one-label-per-message convention, a message always lives in exactly one
"folder"/vfolder. Constraint from lieer: only one of `inbox`/`spam`/`trash`
can stick (trash > spam > inbox); `draft`/`sent` are read-only locally.

## Migrating from offlineimap

- **Plan a full re-download.** Lieer has no import: it will not adopt or
  push messages that appear in its maildir by other means, so an old
  offlineimap maildir cannot be seeded into `~/mail/<acct>`. `gmi sync`
  after `gmi init` fetches the whole account (slow the first time; the
  timer copes with interruptions since sync is resumable).
- Keep the old offlineimap maildir (`~/.mutt/<acct>/...`) **outside**
  `~/mail`, or notmuch will index everything twice.
- Flags survive server-side: read/flagged state comes back from Gmail as
  labels/flags, so nothing needs copying locally.
- Disable the old sync first:
  `systemctl --user disable --now offlineimap.timer offlineimap@<acct>.service`.

## Legacy reference

- `packages/mail/.config/systemd/user/offlineimap{.service,.timer,@.service}`
  — the IMAP-era sync units. Kept, not deployed by default.
- `templates/local-dots/packages/mail/.offlineimaprc` and
  `.davmail.properties` — offlineimap account config and the davmail
  bridge (o365/Exchange). Still the path for non-Gmail accounts.
