#!/bin/bash

if test ! $(which brew); then
    echo "Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing homebrew packages..."

# Add taps
taps=(
    caskroom/cask
    homebrew/dupes
    homebrew/python
)
typeset -U taps

echo "brew tap $taps" >> ~/brew_commands
brew tap $taps

formulae=(
    # cli tools
    exa
    bat
    fortune
    httpie
    lolcat
    mtr
    ncdu
    toilet
    sloccount
    ripgrep
    sift
    the_silver_searcher
    wget

    # development tools
    entr
    git
    git-lfs
    github-keygen
    pinentry
    hub
    reattach-to-user-namespace
    tmux
    neovim
    jq
    watch
    weechat
    zsh

    # haskell for git-status
    ghc
    haskell-stack

    # Plaintext Conversion
    graphviz
    pandoc

    pyenv

    # gnu replacements
    autoconf
    automake
    cmake
    coreutils
    curl
    findutils
    fd
    gawk
    gnu-getopt
    gnu-indent
    gnu-sed
    gnu-tar
    gnutls
    grep
    iproute2mac
    less
    rsync
    ssh-copy-id
    unar

    # utilities
    htop
    m-cli  # Help with macOS magic commands
    nmap
    todo-txt
)
typeset -U formulae

echo "brew install $formulae 2>&1 | tee ~/brewed_formulae" >> ~/brew_commands
brew install $formulae 2>&1 | tee ~/brewed_formulae

echo "brew install aspell --with-lang-en 2>&1 | tee ~/brewed_aspell" >> ~/brew_commands
brew install aspell --with-lang-en 2>&1 | tee ~/brewed_aspell
echo "brew install weechat --with-aspell --with-curl --with-python --with-perl --with-ruby --with-lua --with-guile 2>&1 | tee ~/brewed_weechat" >> ~/brew_commands
brew install weechat --with-aspell --with-curl --with-python --with-perl --with-ruby --with-lua --with-guile 2>&1 | tee ~/brewed_weechat

# casks (apps)
casks=(
    alfred
    authy
    bartender
    charles
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
    lastpass
    numi
    pycharm
    skim
    spotify
    vlc

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

echo "brew cask install $casks 2>&1 | tee ~/brewed_casks" >> ~/brew_commands
brew cask install $casks 2>&1 | tee ~/brewed_casks

# latex
echo "brew cask install mactex &> ~/brewed_mactex &"
brew cask install mactex &> ~/brewed_mactex &
