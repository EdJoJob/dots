# Lieer (gmi) per-account setup

Lieer syncs one Gmail account per directory under `~/mail` via the Gmail
API — no IMAP, no app passwords — and maps labels <-> notmuch tags both
ways. Full picture in `docs/MAIL.md`; upstream docs at
<https://lieer.gaute.vetsj.com/> (repo: <https://github.com/gauteh/lieer>).

## One-time prerequisites

1. Install `notmuch` and `lieer` (`gmi` comes from the `lieer` package on
   installed via mise+uvx on every platform — see `install/tools.sh`).
2. Copy `.notmuch-config` from this directory to `~/.notmuch-config`, set
   your name/addresses, keep `database.path` = `~/mail`.
3. `mkdir -p ~/mail && notmuch new` — creates the (empty) database lieer
   needs before init.

## Per account

```sh
mkdir -p ~/mail/acct        # short name; becomes the path: scope in queries
cd ~/mail/acct
gmi init acct@gmail.com     # opens the OAuth consent flow in a browser
gmi sync                    # first pull downloads everything — can take a while
```

OAuth notes (as of lieer 1.6):

- lieer ships a **shared public OAuth client id**. It cannot read your data
  without your token, but the API quota is shared and Google shows an
  "unverified app" warning. Authorizing an already-logged-in account
  sometimes fails — upstream suggests a private/incognito window and
  logging in with username/password.
- To use your own client id instead: create a GCP project, enable the Gmail
  API, configure a consent screen with the `https://mail.google.com/` scope,
  create a *Desktop app* credential, download `client_secret.json`, then
  `gmi auth -c path/to/client_secret.json -f`.
- The token lands in `.credentials.gmailieer.json` inside the account
  directory. It is secret; the notmuch `new.ignore` pattern in the example
  config keeps it (and lieer's state files) out of the index.

Then enable the periodic sync (units in `packages/mail`):

```sh
# Linux; on macOS load the launchd agent instead (docs/MAIL.md "Scheduling")
systemctl --user enable --now lieer-sync@acct.timer
```

Repeat per account (`~/mail/work`, `lieer-sync@work.timer`, ...).

## Caveats

- **No local ingestion**: lieer does not push messages you drop into the
  maildir yourself — don't copy an old offlineimap maildir into `~/mail`.
  Migration = fresh download (see `docs/MAIL.md`).
- Only one of `inbox`/`spam`/`trash` sticks per message (trash > spam >
  inbox); `draft` and `sent` are read-only from the local side.
- `gmi sync` = push then pull; local/remote conflicts are not pushed unless
  forced (`gmi push -f`), and the following pull makes remote win.
