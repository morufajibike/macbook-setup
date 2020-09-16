#!/bin/bash

# Install homebrew
echo "--- Installing homebrew ---"
if [ -z "$(brew --version)" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    echo "Homebrew already installed. updating..."
    brew update
fi

# Install productivity packages
for pkg in `cat packages.txt`
    do
        echo "--- Installing $pkg ---"
        if [ -z "$($pkg --version)" ]; then
	    echo "Installing..."
            brew install $pkg
        else
            echo "$pkg already installed. skipping..."
        fi
    done

# Install oh-my-zsh
echo "--- Installing oh-my-zsh ---"
/bin/bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

mkdir -p ~/.vim/autoload ~/.vim/bundle && \
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

git clone https://github.com/preservim/nerdtree.git ~/.vim/bundle/nerdtree

echo '[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"' >> ~/.bash_profile

# Install tmux plugin manager
echo "--- Cloning tmux plugin manager to ~/.tmux/plugins/tpm ---"
if [ -d "~/.tmux/plugins/tpm" ]; then
    echo "tmux plugin manager already installed. skipping..."
else
    echo "Cloning..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
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


echo "--- Install docker ---"
brew install docker docker-compose docker-machine xhyve docker-machine-driver-xhyve

echo "--- Installing $pkg ---"
if [ -z "$($pkg --version)" ]; then
	echo "Installing..."
            brew install $pkg
        else
            echo "$pkg already installed. skipping..."
        fi

brew cask install iterm2
brew cask install google-chrome
brew cask install visual-studio-code
brew cask install docker
brew cask install flux
brew cask install postman
brew cask install whatsapp

# (optional) set default shell
# chsh -s /bin/zsh

./create-ssh-key.sh

git config --global user.email "abiodun.ajibike1@yahoo.com"
git config --global user.name "Moruf Ajibike"

tmux source ~/.tmux.conf
