#!/usr/bin/env bash
# scripts/40-tmux.sh -- install TPM and run plugin installation non-interactively.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

# ---------------------------------------------------------------------------
# Tmux Plugin Manager (TPM)
# ---------------------------------------------------------------------------

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [[ -d "${TPM_DIR}" ]]; then
  info "TPM already present -- skipping clone."
else
  info "Cloning TPM..."
  ensure_dir "${HOME}/.tmux/plugins"
  run git clone --depth=1 \
    https://github.com/tmux-plugins/tpm \
    "${TPM_DIR}"
fi

# ---------------------------------------------------------------------------
# Install tmux plugins
# ---------------------------------------------------------------------------

INSTALL_SCRIPT="${TPM_DIR}/bin/install_plugins"

if [[ -x "${INSTALL_SCRIPT}" ]]; then
  info "Installing tmux plugins via TPM..."
  # TPM's install_plugins script reads ~/.tmux.conf for the plugin list.
  # TMUX is deliberately unset so the script runs in a non-attached context.
  run env TMUX="" "${INSTALL_SCRIPT}"
else
  warn "TPM install script not found at ${INSTALL_SCRIPT} -- plugins not installed."
fi

info "40-tmux: done."
