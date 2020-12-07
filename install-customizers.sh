#!/bin/bash

# install fonts
# source https://github.com/kiliman/operator-mono-lig
pip3 install fonttools

custom_zsh_dir=$HOME/Documents/Personal/ZSH

# clear out $custom_zsh_dir
rm -rf $custom_zsh_dir/*

mkdir -p $custom_zsh_dir

# clone Colour Schemes
git clone https://github.com/mbadolato/iTerm2-Color-Schemes.git $custom_zsh_dir/iTerm2-Color-Schemes

# install FiraCode
git clone https://github.com/tonsky/FiraCode.git $custom_zsh_dir/FireCode

# clone Operator Mono
git clone https://github.com/kiliman/operator-mono-lig.git $custom_zsh_dir/operator-mono-lig
cp -r ./fonts/* $custom_zsh_dir/original
cd $custom_zsh_dir/operator-mono-lig
npm install
./build.sh

# install powerline fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Add Syntax Highlighting Plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Add ZSH-AutoSuggestion Plugin
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

cd $HOME/Documents/macbook-setup
