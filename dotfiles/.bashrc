# ~/.bashrc — sourced for interactive bash shells.

# Shared aliases and functions.
source ~/.bash_additions

# pyenv initialisation.
export PATH="$HOME/.pyenv/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Bash completion (Homebrew).
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] \
  && source "/usr/local/etc/profile.d/bash_completion.sh"

# kubectl bash completion.
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
fi

# Rust / cargo environment.
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
