#!/bin/bash

echo "Installing dotfiles"

echo "Initializing submodule(s)"
git submodule update --init --recursive

source install/link.sh

if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"

    echo "Brewing all the things"
    source install/brew.sh
fi

if [ "$(uname)" == "Linux" ]; then
    if which apt &>/dev/null; then
        source install/apt.sh
    fi
    source install/rust.sh
fi

echo "Making untracked local config files"
touch ~/.local_zshrc
touch ~/.local_vimrc
touch ~/.local_tmux.conf
touch ~/.local_gitconfig

echo "Enabling hg extentions"
source install/mercurial.sh

echo "Installing all pipx tools"
source install/pipx.sh

echo "Installing all ruby tools"
source install/ruby.sh

echo "Installing all npm tools"
source install/npm.sh

echo "Installing tmux terminfo"
tic tmux/tmux-256color.terminfo

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
