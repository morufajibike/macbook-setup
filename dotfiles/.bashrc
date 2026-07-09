# ~/.bashrc — sourced for interactive bash shells.

# Shared aliases and functions.
source ~/.bash_additions

source ~/.bash_custom_additions

# pyenv initialisation.
export PATH="$HOME/.pyenv/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Resolve the Homebrew prefix (Apple Silicon: /opt/homebrew, Intel: /usr/local)
# without spawning brew, so the per-arch path below is not hardcoded.
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  BREW_PREFIX="${HOMEBREW_PREFIX}"
elif [ -x /opt/homebrew/bin/brew ]; then
  BREW_PREFIX="/opt/homebrew"
elif [ -x /usr/local/bin/brew ]; then
  BREW_PREFIX="/usr/local"
else
  BREW_PREFIX=""
fi

# Bash completion (Homebrew).
[ -n "${BREW_PREFIX}" ] \
  && [ -r "${BREW_PREFIX}/etc/profile.d/bash_completion.sh" ] \
  && source "${BREW_PREFIX}/etc/profile.d/bash_completion.sh"

# kubectl bash completion.
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
fi

# Rust / cargo environment.
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
