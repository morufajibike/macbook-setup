
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Add github private key for SSH connections
ssh-add -K ~/.ssh/id_rsa_github

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/Users/kurtpeek/Downloads/google-cloud-sdk/path.bash.inc' ]; then
#  source '/Users/kurtpeek/Downloads/google-cloud-sdk/path.bash.inc';
# fi

# The next line enables shell command completion for gcloud.
#if [ -f '/Users/kurtpeek/Downloads/google-cloud-sdk/completion.bash.inc' ]; then
#  source '/Users/kurtpeek/Downloads/google-cloud-sdk/completion.bash.inc';
#fi

#pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

source <(kubectl completion bash)

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
