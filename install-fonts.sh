#!/bin/bash

# install fonts
# source https://github.com/kiliman/operator-mono-lig
pip3 install fonttools

git clone https://github.com/kiliman/operator-mono-lig.git $HOME/operator-mono-lig
cp -r ./fonts/* $HOME/operator-mono-lig/original
cd $HOME/operator-mono-lig
npm install
./build.sh


git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

cd $HOME/Documents/macbook-setup
