# local-dots — private per-machine dotfiles side-car

This repo holds everything machine- or identity-specific that must NOT live in
the public dotfiles repo: tokens (via `op read`, never plaintext), work host
aliases, per-machine git identity, ssh Host stanzas, mail accounts.

It is deployed by the same tool as the main repo:

    dots link        # stows main repo AND this side-car; any path both repos
                    # claim is a hard error before anything changes

Layout mirrors the main repo: `packages/<pkg>/<literal $HOME-relative path>`,
selected by `manifests/common` (+ `manifests/darwin` / `manifests/linux`).

This scaffold ships starter files at the real `.local_*` paths. On a machine
that already has real versions, replace the seeded examples (`mv
~/.local_zshrc packages/core/.local_zshrc`), then `dots link`. For anything the
scaffold does not ship, adopt it (moves it here, leaves a symlink):

    dots adopt -s -p core ~/.local_something

The main repo's configs source these files with graceful guards — a missing
file never breaks a fresh machine, it just means "no local overrides yet".
