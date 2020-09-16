#!/bin/bash

if [ -f ~/.ssh/id_rsa_github ]; then
   echo "SSH key ~/.ssh/id_rsa_github already exist. Skipping..."
else
   echo "Creating Github SSH key..."
   ssh-keygen -t rsa -b 4096 -C "abiodun.ajibike1@yahoo.com" -f ~/.ssh/id_rsa_github -P ""

   eval "$(ssh-agent -s)"

   echo "
   Host github.com
      HostName github.com
      PreferredAuthentications publickey
      IdentityFile ~/.ssh/id_rsa_github" >> ~/.ssh/config

   ssh-add -K ~/.ssh/id_rsa_github

   cat ~/.ssh/id_rsa_github.pub
fi
