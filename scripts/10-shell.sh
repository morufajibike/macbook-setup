#!/usr/bin/env bash
# scripts/10-shell.sh — install oh-my-zsh plus required themes and plugins.
#
# This is the single, authoritative source for shell customisation.
# All clone operations are idempotent: they are skipped if the target
# directory already exists.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

# ---------------------------------------------------------------------------
# oh-my-zsh
# ---------------------------------------------------------------------------

if [[ -d "${HOME}/.oh-my-zsh" ]]; then
  info "oh-my-zsh already installed — skipping."
else
  info "Installing oh-my-zsh (unattended)..."
  # RUNZSH=no prevents the installer from launching a new zsh session.
  # CHSH=no prevents the installer from changing the login shell (we manage
  # that separately or it is already set).
  RUNZSH=no CHSH=no \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"

# ---------------------------------------------------------------------------
# Theme: powerlevel10k
# ---------------------------------------------------------------------------

POWERLEVEL10K_DIR="${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"

if [[ -d "${POWERLEVEL10K_DIR}" ]]; then
  info "powerlevel10k already present — skipping clone."
else
  info "Cloning powerlevel10k theme..."
  git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    "${POWERLEVEL10K_DIR}"
fi

# ---------------------------------------------------------------------------
# Plugin: zsh-syntax-highlighting
# ---------------------------------------------------------------------------

ZSH_SYNTAX_DIR="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

if [[ -d "${ZSH_SYNTAX_DIR}" ]]; then
  info "zsh-syntax-highlighting already present — skipping clone."
else
  info "Cloning zsh-syntax-highlighting plugin..."
  git clone --depth=1 \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_SYNTAX_DIR}"
fi

# ---------------------------------------------------------------------------
# Plugin: zsh-autosuggestions
# ---------------------------------------------------------------------------

ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

if [[ -d "${ZSH_AUTOSUGGEST_DIR}" ]]; then
  info "zsh-autosuggestions already present — skipping clone."
else
  info "Cloning zsh-autosuggestions plugin..."
  git clone --depth=1 \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    "${ZSH_AUTOSUGGEST_DIR}"
fi

info "10-shell: done."
