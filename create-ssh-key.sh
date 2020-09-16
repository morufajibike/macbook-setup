#!/bin/bash

echo "Create Github SSH key"
ssh-keygen -t rsa -b 4096 -C "abiodun.ajibike1@yahoo.com" -f $HOME/.ssh/id_rsa_github -P ""

#eval "$(ssh-agent -s)"

echo "
Host github.com
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_rsa_github" >> ~/.ssh/config
