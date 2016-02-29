#!/bin/bash

echo "Installing dotfiles"

echo "Initializing submodule(s)"
git submodule update --init --recursive

source install/link.sh

if [ "$(uname)" == "Darwin" ]; then
    echo "Running on OSX"

    echo "Brewing all the things"
    source install/brew.sh

    echo "Updating OSX settings"
    source install/osx.sh

    echo "Running tmux movement fixes"
    source tmux/tmux_fixes.sh
fi

echo "Enabling hg extentions"
source install/mercurial.sh

echo "Installing python modules"
source install/python.sh

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Done."
