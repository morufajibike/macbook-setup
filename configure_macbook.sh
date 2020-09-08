#!/bin/bash

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

