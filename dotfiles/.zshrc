# Enable powerlevel10k instant prompt. Keep this block at the very top so it
# runs before anything that produces output; otherwise the instant prompt is
# disabled with a warning. Console output during init must stay above this.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Skip verification of insecure completion directories.
ZSH_DISABLE_COMPFIX="true"

# Theme: powerlevel10k.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins — keep this list lean; slow plugins degrade shell start time.
plugins=(git autopep8 pep8 aws tmux zsh-syntax-highlighting zsh-autosuggestions)

source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# PATH additions
# ---------------------------------------------------------------------------

# OpenSSL (1.1 required by some Python packages and older tooling).
# These are Intel-prefix paths (/usr/local); guard so dead paths are not
# added on Apple Silicon, mirroring the arch-aware handling in .vimrc.
if [ -d /usr/local/opt/openssl@1.1 ]; then
  export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
fi

# OpenSSL (legacy path used by some tools on Intel Macs).
if [ -d /usr/local/opt/openssl ]; then
  export PATH="/usr/local/opt/openssl/bin:$PATH"
  export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib:${DYLD_LIBRARY_PATH:-}
fi

# MySQL client (for building Python/Ruby MySQL extensions).
if [ -d /opt/homebrew/opt/mysql-client ]; then
  export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql-client/lib/pkgconfig"
fi
if [ -d /usr/local/opt/mysql-client ]; then
  export PATH="/usr/local/opt/mysql-client/bin:$PATH"
fi

# Java 11 (via Homebrew openjdk@11).
if [ -d /usr/local/opt/openjdk@11 ]; then
  export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
fi
export PATH="$PATH:/usr/bin/java"
export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || true)

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

# pyenv — initialise every new shell so the shims are on PATH.
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# NVM — Node Version Manager.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]             && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ]    && source "$NVM_DIR/bash_completion"

# Rust / cargo environment (installed by rustup).
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# ---------------------------------------------------------------------------
# Aliases and shell additions
# ---------------------------------------------------------------------------

alias k=kubectl

# Shared aliases and functions (git shortcuts, project helpers, etc.).
source ~/.bash_additions

# ---------------------------------------------------------------------------
# Claude Code tmux wrapper
# ---------------------------------------------------------------------------
# Always start Claude Code inside a tmux session so agent teams render in
# split panes. CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (set in
# ~/.claude/settings.json) spawns each teammate in its own tmux pane, but
# only when Claude is launched from inside a tmux client. This wrapper
# enforces that: outside tmux it creates/attaches to a session named
# `claude` and runs `claude` inside it; inside tmux it runs claude normally.
claude() {
  if [[ -z "$TMUX" ]]; then
    command tmux new-session -A -s claude "command claude $*"
  else
    command claude "$@"
  fi
}

# powerlevel10k prompt configuration. If ~/.p10k.zsh is absent, p10k runs its
# interactive `p10k configure` wizard automatically on first shell launch.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
