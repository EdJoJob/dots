#!/bin/bash

if test ! $(which brew); then
    echo "Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing homebrew packages..."

# Add taps
taps=(
    danielbayley/alfred
    caskroom/cask
    homebrew/dupes
    homebrew/python
)
typeset -U taps
brew tap $taps

formulae=(
    # cli tools
    exa
    fortune
    lolcat
    toilet
    sloccount
    ripgrep
    sift
    the_silver_searcher
    wget

    # development tools
    git
    git-lfs
    pinentry
    hub
    reattach-to-user-namespace
    tmux
    neovim
    jq
    vim
    watch
    zsh

    # haskell for git-status
    ghc
    haskell-stack

    # Plaintext Conversion
    graphviz
    pandoc

    pyenv
    pyenv-virtualenv
    python
    python3

    # gnu replacements
    autoconf
    automake
    cmake
    coreutils
    curl
    findutils
    gawk
    gnu-getopt
    gnu-indent
    gnu-sed
    gnu-tar
    gnupg
    gnutls
    grep
    homebrew/dupes/expect # Needed for tmux tests
    homebrew/dupes/gpatch
    iproute2mac
    less
    rsync
    ssh-copy-id
    unar

    # utilities
    htop-osx
    m-cli  # Help with macOS magic commands
    nmap
    mrt 
    todo-txt
)
typeset -U formulae

brew install $formulae 2>&1 | tee ~/brewed_formulae

brew install aspell --with-lang-en 2>&1 | tee ~/brewed_aspell
brew install weechat --with-aspell --with-curl --with-python --with-perl --with-ruby --with-lua --with-guile 2>&1 | tee ~/brewed_weechat

# casks (apps)
casks=(
    alfred
    alfred-numi
    bartender
    chicken
    docker
    dropbox
    firefox
    flux
    gimp
    google-chrome
    gpg-suite-pinentry
    intellij-idea-ce
    istat-menus
    iterm2
    joplin
    keybase
    numi
    pycharm
    skim
    spotify
    synergy
    wireshark

    # Quicklook extentions
    qlcolorcode
    qlimagesize
    qlmarkdown
    qlmobi
    qlprettypatch
    qlrest
    qlstephen
    quicklook-csv
    quicklook-json
    suspicious-package

    # tiling window manager for OSX
    amethyst
)

typeset -U casks

brew cask install $cask 2>&1 | tee ~/brewed_casks

# latex
brew cask install mactex & &> ~/brewed_mactex
