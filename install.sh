#!/usr/bin/env bash
# install.sh — idempotent macOS bootstrap entrypoint.
#
# Usage:
#   ./install.sh
#
# Runs all numbered scripts under scripts/ in ascending numeric order.
# Safe to re-run: every script is designed to be idempotent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

info "Starting macOS bootstrap from: ${SCRIPT_DIR}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This bootstrap is intended for macOS only."
  exit 1
fi

# ---------------------------------------------------------------------------
# Run numbered scripts in order
# ---------------------------------------------------------------------------

find "${SCRIPT_DIR}/scripts" -name '[0-9]*.sh' | sort | while read -r script; do
  if [[ ! -f "${script}" ]]; then
    # Should be unreachable (find only yields existing files), but guards
    # defensively against a race where a script is removed mid-run.
    err "Expected script no longer exists: ${script}"
    exit 1
  fi
  info "Running: ${script}"
  # Scripts are always invoked via bash, so the executable bit is not
  # required. We deliberately do NOT skip on a missing +x: that would
  # silently drop a step and still report overall success.
  bash "${script}"
  info "Completed: ${script}"
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n'
info "Bootstrap complete. All scripts ran successfully."
info "Dotfiles are symlinked from: ${SCRIPT_DIR}/dotfiles"
info "Backups of replaced files are in: ${HOME}/dotfiles-backup"
info ""
info "Next steps:"
info "  • Vim plugins: open vim and run :PluginInstall"
info "  • Tmux plugins: inside tmux press prefix + I"
info "  • Add your GitHub SSH key (~/.ssh/id_ed25519_github.pub) to https://github.com/settings/keys"
