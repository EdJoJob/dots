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

rm ~/.config/nvim/init.vim
ln -s ~/.vimrc ~/.config/nvim/init.vim

rm ~/.todo/todo
ln -s ~/Dropbox/todo ~/.todo/todo

mkdir -m 700  ~/.ssh
ln -s ~/.ssh/config ~/dots/sshconfig
mkdir -p ~/.ssh/config.d
ln -s /Volumes/Keybase/private/edjojob/sshconfig ~/.ssh/config.d/personal
