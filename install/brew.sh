#!/bin/bash

if test ! $(which brew); then
    echo "Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing homebrew packages..."

# Add taps
taps=(
    homebrew/cask
)
typeset -U taps

echo "brew tap $taps" >> ~/brew_commands
for tap in $taps; do
    brew tap $tap
done

formulae=(
    # cli tools
    exa
    bat
    fortune
    git-delta
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

# See https://github.com/github/hub/pull/1962
# We need to remove the gitcontrib git completion function to allow the _hub completion to work
rm $(brew --prefix)/share/zsh/site-functions/_git

# casks (apps)
casks=(
    alfred
    authy
    bartender
    charles
    chicken
    homebrew/cask/docker
    dropbox
    firefox
    homebrew/cask/flux
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

    # tiling window manager for OSX
    amethyst
)

typeset -U casks

echo "brew install $casks 2>&1 | tee ~/brewed_casks" >> ~/brew_commands
for cask in $casks; do
    brew install $cask 2>&1 | tee ~/brewed_casks
done

# latex
echo "brew install mactex &> ~/brewed_mactex &"
brew install mactex &> ~/brewed_mactex &
