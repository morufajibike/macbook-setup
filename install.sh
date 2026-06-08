#!/usr/bin/env bash
# install.sh -- idempotent macOS bootstrap entrypoint.
#
# Usage:
#   ./install.sh [--with-apps] [--dry-run|-n] [--help|-h]
#
# Options:
#   --with-apps     Also install the apps group (GUI casks). Skipped by default.
#                   Also activated by setting INSTALL_APPS=1 in the environment.
#   --dry-run, -n   Preview every action without making any change to the
#                   system. Also activated by setting DRY_RUN=1 in the
#                   environment before running.
#   --help,    -h   Print this usage and exit.
#
# Runs all numbered scripts under scripts/ in ascending numeric order.
# Safe to re-run: every script is designed to be idempotent.
#
# DRY_RUN and INSTALL_APPS are exported so every child script inherits them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

_print_usage() {
  printf 'Usage: %s [--with-apps] [--dry-run|-n] [--help|-h]\n\n' "$(basename "$0")"
  printf 'Options:\n'
  printf '  --with-apps     Also install the apps group (GUI casks). Skipped by default.\n'
  printf '                  Also activated by INSTALL_APPS=1 in the environment.\n'
  printf '  --dry-run, -n   Preview all actions without making any system change.\n'
  printf '                  Also activated by DRY_RUN=1 in the environment.\n'
  printf '  --help,    -h   Print this message and exit.\n'
}

for _arg in "$@"; do
  case "${_arg}" in
  --with-apps)
    INSTALL_APPS=1
    export INSTALL_APPS
    ;;
  --dry-run | -n)
    DRY_RUN=1
    export DRY_RUN
    ;;
  --help | -h)
    _print_usage
    exit 0
    ;;
  *)
    err "Unknown option: ${_arg}"
    _print_usage >&2
    exit 1
    ;;
  esac
done
unset _arg

# lib/common.sh already defaulted DRY_RUN to 0 if unset; the flag above
# may have overridden it to 1.  Either way, export so child scripts inherit.
export DRY_RUN

# apps is opt-in: default INSTALL_APPS to 0 when unset, then export so child
# scripts inherit it even when the flag/env var was not provided.
: "${INSTALL_APPS:=0}"
export INSTALL_APPS

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

if [[ "${DRY_RUN}" == "1" ]]; then
  info "DRY RUN -- no changes will be made."
fi

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
if [[ "${DRY_RUN}" == "1" ]]; then
  info "DRY RUN complete. No changes were made."
else
  info "Bootstrap complete. All scripts ran successfully."
  info "Dotfiles are symlinked from: ${SCRIPT_DIR}/dotfiles"
  info "Backups of replaced files are in: ${HOME}/dotfiles-backup"
  info ""
  info "Next steps:"
  info "  * Vim plugins: open vim and run :PluginInstall"
  info "  * Tmux plugins: inside tmux press prefix + I"
  info "  * Add your GitHub SSH key (~/.ssh/id_ed25519_github.pub) to https://github.com/settings/keys"
fi
