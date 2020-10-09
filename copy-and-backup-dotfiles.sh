#!/bin/bash

backup_dir=$HOME/dotfiles-backup

mkdir -p $backup_dir

echo "Backing up dotfiles to $backup_dir"

for dotfile in .bashrc .zshrc .vimrc .tmux.conf
do
    echo "--- About to backup and/or copy $dotfile ---"
    if [ -f "$HOME/$dotfile" ]; then
      # put backup files in own dir
      backup_folder_name="${dotfile:1}"

      mkdir -p $backup_dir/$backup_folder_name

      echo "----- backing up $dotfile -----"
      timestamp=$(date +%s)
      echo "----- backup timestamp for $dotfile is: $timestamp -----"
      cp $HOME/$dotfile $backup_dir/$backup_folder_name/$dotfile.$timestamp
    else
      echo "----- $dotfile copy does not exist in $HOME -----"
    fi

    echo "----- copying dotfiles/$dotfile to $HOME/$dotfile -----"
    cp dotfiles/$dotfile $HOME/$dotfile
    #. $HOME/$dotfile
done


