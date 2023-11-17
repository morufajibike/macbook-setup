#!/bin/bash

# Install python 3.9.6 (New Macbooks now come with python3.8 as of the time of writing this)
if [ -z "$(pyenv --version)" ]; then
  echo "--- Installing pyenv ---"
  pyenv install 3.9.6
  pyenv global 3.9.6
else
  echo "pyenv already installed. skipping..."
fi

PYENV_PATH="$(pyenv root)/shims"
if grep -Fxq "$PYENV_PATH" /etc/paths > /dev/null; then
   echo "$PYENV_PATH already set in /etc/paths"
else
   echo $PYENV_PATH | sudo tee -a /etc/paths
fi

pip install flake8
pip install ipython
pip install pytest
