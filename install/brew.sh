#!/bin/sh

if test ! $(which brew); then
    echo "Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing homebrew packages..."

# Add taps

brew tap caskroom/cask
brew tap homebrew/command-not-found
brew tap homebrew/python
brew tap homebrew/dupes
brew tap neovim/neovim

# cli tools
brew install the_silver_searcher
brew install tree
brew install wget
brew install sloccount

# development tools
brew install git
brew install reattach-to-user-namespace
brew install tmux
brew install zsh
brew install python
brew install python3

# gnu replacements
brew install autoconf
brew install automake
brew install cmake
brew install curl
brew install coreutils
brew install gawk
brew install gnu-getopt
brew install homebrew/dupes/gpatch
brew install homebrew/dupes/expect # Needed for tmux tests
brew install gnu-indent
brew install gnu-sed
brew install gnu-tar
brew install gnupg
brew install gnutls
brew install grep
brew install iproute2mac
brew install less
brew install unar
brew install findutils

# utilities
brew install htop-osx
brew install irssi
brew install todo-txt
brew install highlight
brew install pandoc

# install neovim
brew install neovim/neovim/neovim --HEAD

# casks (apps)
brew cask install 1password
brew cask install alfred
brew cask install chicken
brew cask install dropbox
brew cask install dash
brew cask install firefox
brew cask install flash
brew cask install github-desktop
brew cask install google-chrome
brew cask install google-drive
brew cask install google-hangouts
brew cask install pycharm
brew cask install skim
brew cask install skype
brew cask install sourcetree
brew cask install spotify
brew cask install spotify-notifications
brew cask install wireshark

# Keybind editors
brew cask install karabiner
brew cask install seil

# Quicklook extentions
brew cask install betterzipql
brew cask install qlcolorcode
brew cask install qlimagesize
brew cask install qlmarkdown
brew cask install qlprettypatch
brew cask install qlstephen
brew cask install quicklook-csv
brew cask install quicklook-json
brew cask install suspicious-package

# tiling window manager for OSX
brew cask install amethyst
