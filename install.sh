#!/bin/bash

# Install google chrome
echo "-- Install Google Chrome browser ---"
if [ -f "/Applications/Chrome.app" ]; then
    wget https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg
    open ~/Downloads/googlechrome.dmg
    sudo cp -r /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/
else
    echo "Google chrome already installed. skipping..."
fi

# Install homebrew
echo "--- Installing homebrew ---"
if [ -z "$(brew --version)" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    echo "Homebrew already installed. updating..."
    #brew update
fi

# Install productivity packages
for pkg in `cat packages.txt`
    do
        echo "--- Installing $pkg ---"
        if [ -z "$($pkg --version)" ]; then
	    echo "Installing..."
            #brew cask install $pkg
        else
            echo "$pkg already installed. skipping..."
        fi
    done

# Install tmux plugin manager
echo "--- Cloning tmux plugin manager to ~/.tmux/plugins/tpm ---"
if [ -d "~/.tmux/plugins/tpm" ]; then
    echo "Cloning..."
    #git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo "tmux plugin manager already installed. skipping..."
fi

# Install oh-my-zsh
echo "--- Installing oh-my-zsh ---"
if [ -z "$(zsh --version)" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

for dotfile in .zshrc .vimrc .tmux.conf
do
    if [ -f "$HOME/$dotfile" ]; then
        echo "--- backing up $HOME/$dotfile to $HOME/$dotfile.backup---"
    	# cp $HOME/$dotfile $HOME/$dotfile.backup
    fi

    echo "--- copying dotfiles/$dotfile to $HOME/$dotfile ---"
    cp dotfiles/$dotfile $HOME/$dotfile
    #. $HOME/$dotfile
done

tmux source $HOME/.tmux.conf

echo "--- Install docker ---"
brew install docker docker-compose docker-machine xhyve docker-machine-driver-xhyve

sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve 
sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
docker-machine create default --driver xhyve --xhyve-experimental-nfs-share

