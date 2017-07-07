#!/usr/bin/env zsh

DOTFILES=$HOME/dots

echo -e "\nCreating symlinks"
echo "=============================="
linkables=$( find -H "$DOTFILES" -maxdepth 3 -name '*.symlink' )
for file in $linkables ; do
    target="$HOME/.$( basename $file ".symlink" )"
    if [ -e $target ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s $file $target
    fi
done

echo -e "\nLinking 'special' files"
echo "==========================="
ln -s ~/Dropbox/todo ~/.todo/todo
mkdir -p ~/.config
ln -s ~/.vim ~/.config/nvim

mkdir -m 700  ~/.ssh
ln -s ~/.ssh/config ~/dots/sshconfig
