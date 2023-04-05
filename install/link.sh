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
mkdir -p ~/.config
ln -s ~/.vim ~/.config/nvim

for f in $(ls $DOTFILES/config); do
    ln -s $f ~/.config/
done

rm ~/.config/nvim/init.vim
ln -s ~/.vimrc ~/.config/nvim/init.vim

rm ~/.todo/todo

mkdir -m 700  ~/.ssh
ln -s  ~/dots/sshconfig ~/.ssh/config
mkdir -p ~/.ssh/config.d
