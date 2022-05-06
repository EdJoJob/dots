# My dotfiles and configuration

## Install
Run `install.sh`

_YMMV, I don't do this often.  There are likely **many** bugs_

## General Rules

* Any file/dir with `$FILENAME.symlink` is linked as a `.$FILENAME` in the home directory
* Have a real `.local_$PROG_CONF` in the home directory for device specific config

## The list what tools I use for what

_because otherwise **I** forget_

* File Watching: `entr`
* Editing: `nvim` (neovim, but aliased to `vi` because I am extremely lazy AND often on remote systems)
* Repeated commands: `watch` from procps-ng
* Shell: `zsh`
* Browser: `firefox` for TreeStyleTabs
* Markdown Preview for GitHub: `grip`
* Normal Regex Searching: `rg` for rip-grep
* Fancier-searching: `sift` because context often matters
* HoRNDIS: for USB internet for android (`brew cask install horndis`)
* ngrok: for ad-hoc port-forwarding and/or NAT punch-through
* `gh-auth`: getting public keys from github (github-auth gem)
* `gron` and `jq`: look through json
* `xq` for XML, `yq` for yaml


## TODO
* [ ] Make example `.local` files, becasue I keep forgetting what I put in them
* [ ] Check the install process actually does what I want
* [ ] Try get rid of oh-my-zsh for startup speed
