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

# Install oh-my-zsh
echo "--- Installing oh-my-zsh ---"
/bin/bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "--- Installing vim Vundle ---"
mkdir -p ~/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim


BASH_COMPLETION='[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"'
if grep -Fxq "$BASH_COMPLETION" ~/.bash_profile > /dev/null; then
   echo "Bash completion already set in bash_profile"
else
   echo $BASH_COMPLETION >> ~/.bash_profile
fi

# Install tmux plugin manager
echo "--- Cloning tmux plugin manager to ~/.tmux/plugins/tpm ---"
if [ -d ~/.tmux/plugins/tpm ]; then
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

# Install brew packages
for pkg in `cat brew_cask_pkgs.txt`
    do
        echo "--- Installing $pkg with brew cask install ---"
        brew cask install $pkg
    done

# Install python pkgs
./install-python-pkgs.sh

# create github ssh key
./create-ssh-key.sh

git config --global user.email "abiodun.ajibike1@yahoo.com"
git config --global user.name "Moruf Ajibike"

tmux source ~/.tmux.conf
