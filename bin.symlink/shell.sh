#!/usr/bin/env sh

if [ -n "$(command -v zsh)" ]; then
    shellpath=$(command -v zsh)
else
    shellpath=$(command -v bash)
fi

if [ -n "$(command -v reattach-to-user-namespace)" ]; then
    reattach-to-user-namespace $shellpath
else
    exec "$shellpath"
fi
