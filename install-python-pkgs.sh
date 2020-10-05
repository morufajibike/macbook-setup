#!/bin/bash

# Install python3.7.4 (New Macbooks now come with python3.8 as of the time of writing this)
pyenv install 3.7.4
pyenv global 3.7.4

PYENV_PATH="$(pyenv root)/shims"
if grep -Fxq "$PYENV_PATH" /etc/paths > /dev/null; then
   echo "$PYENV_PATH already set in /etc/paths"
else
   echo $PYENV_PATH | sudo tee -a /etc/paths
fi

pip install flake8
