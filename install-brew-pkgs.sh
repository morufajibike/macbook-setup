#!/bin/bash

# Install homebrew
echo "--- Installing homebrew ---"
if [ -z "$(brew --version)" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    echo "Homebrew already installed. updating..."
    brew update
fi

# Install brew packages
for pkg in `cat brew_pkgs.txt`
    do
        echo "--- Installing $pkg with brew install ---"
        if [ -z "$($pkg --version)" ]; then
	    echo "Installing..."
            brew install $pkg
        else
            echo "$pkg already installed. skipping..."
        fi
    done

# Install brew packages
for pkg in `cat brew_cask_pkgs.txt`
    do
        echo "--- Installing $pkg with brew cask install ---"
        brew cask install $pkg
    done

# Clean things up
brew update && \
    brew install `brew outdated` && \
    brew cleanup && \
    brew cask cleanup && \
    brew doctor &&\
    brew tap caskroom/versions


