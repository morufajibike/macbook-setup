#!/usr/bin/env bash
# scripts/30-vim.sh — install Vundle and run PluginInstall non-interactively.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

# ---------------------------------------------------------------------------
# Vundle
# ---------------------------------------------------------------------------

VUNDLE_DIR="${HOME}/.vim/bundle/Vundle.vim"

if [[ -d "${VUNDLE_DIR}" ]]; then
  info "Vundle already present — skipping clone."
else
  info "Cloning Vundle..."
  ensure_dir "${HOME}/.vim/bundle"
  git clone --depth=1 \
    https://github.com/VundleVim/Vundle.vim.git \
    "${VUNDLE_DIR}"
fi

# ---------------------------------------------------------------------------
# Install vim plugins
# ---------------------------------------------------------------------------

if command_exists vim; then
  info "Installing vim plugins via Vundle (non-interactive)..."
  # +PluginInstall runs the plugin installation.
  # +qall closes vim immediately after.
  # -u uses the deployed .vimrc.
  vim -u "${HOME}/.vimrc" +PluginInstall +qall
else
  warn "vim not found — skipping plugin installation."
fi

info "30-vim: done."
