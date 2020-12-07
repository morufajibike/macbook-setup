#!/bin/bash

# Install brew pkgs
./install-brew-pkgs.sh

# Install fuzzy search for vim
./install-fzf.sh

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

if -f ~/.bash_profile; then
    echo "export PATH="$HOME/.pyenv/bin:$PATH""
    echo "eval "$(pyenv init -)""
    echo "eval "$(pyenv virtualenv-init -)""
fi

# Install tmux plugin manager
echo "--- Cloning tmux plugin manager to ~/.tmux/plugins/tpm ---"
if [ -d ~/.tmux/plugins/tpm ]; then
    echo "tmux plugin manager already installed. skipping..."
else
    echo "Cloning..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi


# Install python pkgs
./install-python-pkgs.sh

# create github ssh key
./create-ssh-key.sh

git config --global user.email "abiodun.ajibike1@yahoo.com"
git config --global user.name "Moruf Ajibike"

tmux source ~/.tmux.conf

# create a backup for dotfiles
./copy-and-backup-dotfiles.sh

./install-customizers.sh

### Install vim plugins
vim +PluginInstall +qall
