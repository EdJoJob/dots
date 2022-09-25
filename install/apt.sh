sudo -v

# Python
sudo apt install \
    python-is-python3 \
    python2 \
    python3 \
    python3-gpg \
    python3-pip \
    python3-venv \

# Misc
sudo apt install \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    software-properties-common \

# Utilities
sudo apt install \
    caffeine \
    cargo \
    docker.io \
    espeak \
    fd-find \
    fortune \
    git \
    gnupg-agent \
    htop \
    jq \
    mlocate \
    pinentry-curses \
    redshift-gtk \
    ripgrep \
    tmux \
    todotxt-cli \
    wget \
    zeal \
    zsh \


# non-packaged
tmpdir=$(mktmp -d)
cd $tmpdir
wget https://github.com/dandavison/delta/releases/download/0.4.3/git-delta_0.4.3_amd64.deb
sudo dpkg -i git-delta_0.4.3_amd64.deb
