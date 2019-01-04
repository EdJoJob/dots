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

echo "Making untracked local config files"
touch ~/.local_environment.zsh
touch ~/.local_vimrc
touch ~/.local_tmux.conf
touch ~/.local_gitconfig

echo "Enabling hg extentions"
source install/mercurial.sh

echo "Installing python modules"
source install/python.sh

echo "Enabling hg extentions"
source install/mercurial.sh

echo "Installing tmux terminfo"
tic tmux/tmux-256color.terminfo

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
