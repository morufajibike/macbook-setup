
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Add github private key for SSH connections
ssh-add -K ~/.ssh/id_rsa_github

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kurtpeek/Downloads/google-cloud-sdk/path.bash.inc' ]; then
  source '/Users/kurtpeek/Downloads/google-cloud-sdk/path.bash.inc';
fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kurtpeek/Downloads/google-cloud-sdk/completion.bash.inc' ]; then
  source '/Users/kurtpeek/Downloads/google-cloud-sdk/completion.bash.inc';
fi
