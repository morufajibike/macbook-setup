#!/usr/bin/env bash
# scripts/25-git-identity.sh — set the per-machine git identity.
#
# Runs AFTER 20-dotfiles.sh (which symlinks the tracked .gitconfig with
# placeholder identity) and BEFORE 70-ssh.sh (which reads `git config
# user.email` for the SSH key comment).
#
# The tracked dotfiles/.gitconfig includes ~/.gitconfig.local last, so the
# values written here override the shipped placeholders. ~/.gitconfig.local is
# untracked and never committed.
#
# Non-interactive safety: if stdin is not a TTY, the script does NOT prompt
# (which would hang). Instead it uses the GIT_USER_NAME / GIT_USER_EMAIL
# environment variables if both are set, otherwise it skips with a warning and
# leaves any existing ~/.gitconfig.local untouched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

GITCONFIG_LOCAL="${HOME}/.gitconfig.local"

# git is required: it both reads the current defaults and writes the values
# (so they are correctly escaped). Fail fast with a clear message if absent.
if ! command_exists git; then
  err "git not found — cannot configure git identity. Ensure 00-brew.sh ran successfully."
  exit 1
fi

# ---------------------------------------------------------------------------
# Read current values (defaults for the prompt) from ~/.gitconfig.local
# ---------------------------------------------------------------------------

current_name=""
current_email=""
if [[ -f "${GITCONFIG_LOCAL}" ]]; then
  # -f reads from the specific file only, so we get the local override values
  # rather than the merged global config.
  current_name="$(git config -f "${GITCONFIG_LOCAL}" user.name 2>/dev/null || true)"
  current_email="$(git config -f "${GITCONFIG_LOCAL}" user.email 2>/dev/null || true)"
fi

# ---------------------------------------------------------------------------
# Validation helper
# ---------------------------------------------------------------------------

# A deliberately minimal sanity check: the address must contain an "@". Full
# RFC 5322 validation is not worth the complexity for a personal git identity.
is_valid_email() {
  [[ "$1" == *"@"* ]]
}

# ---------------------------------------------------------------------------
# Write ~/.gitconfig.local
# ---------------------------------------------------------------------------

write_gitconfig_local() {
  local name="$1"
  local email="$2"

  # Boundary guard: reject newlines/carriage returns before writing. A value
  # containing a newline could otherwise smuggle an entire extra config section
  # (e.g. [core] sshCommand) into the file, which — because .gitconfig includes
  # this file — would become live global config and run on the next git op.
  # The interactive read -r path already stops at a newline; this guard applies
  # the same protection uniformly to the non-interactive (env var) path.
  if [[ "${name}" == *$'\n'* || "${name}" == *$'\r'* ||
    "${email}" == *$'\n'* || "${email}" == *$'\r'* ]]; then
    err "Git name/email must not contain newlines or carriage returns."
    exit 1
  fi

  # Let git write the values rather than hand-rendering the file. git escapes
  # newlines and metacharacters, so even if the guard above were bypassed an
  # injected section would be stored as an inert quoted string, not parsed as
  # config (config-injection defence in depth).
  : >"${GITCONFIG_LOCAL}"
  git config -f "${GITCONFIG_LOCAL}" user.name "${name}"
  git config -f "${GITCONFIG_LOCAL}" user.email "${email}"
  info "Wrote git identity to ${GITCONFIG_LOCAL} (name: ${name}, email: ${email})."
}

# ---------------------------------------------------------------------------
# Non-interactive path: no TTY on stdin
# ---------------------------------------------------------------------------

if [[ ! -t 0 ]]; then
  if [[ -n "${GIT_USER_NAME:-}" ]] && [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    if ! is_valid_email "${GIT_USER_EMAIL}"; then
      err "GIT_USER_EMAIL ('${GIT_USER_EMAIL}') does not look like an email address."
      exit 1
    fi
    info "Non-interactive: using GIT_USER_NAME / GIT_USER_EMAIL."
    write_gitconfig_local "${GIT_USER_NAME}" "${GIT_USER_EMAIL}"
  else
    warn "Non-interactive shell and GIT_USER_NAME / GIT_USER_EMAIL not set — skipping git identity."
    warn "Set them in ~/.gitconfig.local manually, or re-run this script from a terminal."
  fi
  info "25-git-identity: done."
  exit 0
fi

# ---------------------------------------------------------------------------
# Interactive path: prompt, accepting the current value on empty input
# ---------------------------------------------------------------------------

read -r -p "Git user name [${current_name}]: " input_name
name="${input_name:-${current_name}}"

while [[ -z "${name}" ]]; do
  warn "A git user name is required."
  read -r -p "Git user name: " name
done

# Loop until a syntactically plausible email is supplied.
email=""
while true; do
  read -r -p "Git email [${current_email}]: " input_email
  email="${input_email:-${current_email}}"

  if [[ -z "${email}" ]]; then
    warn "A git email is required."
    continue
  fi
  if ! is_valid_email "${email}"; then
    warn "'${email}' does not look like an email address (must contain '@'). Try again."
    continue
  fi
  break
done

write_gitconfig_local "${name}" "${email}"

info "25-git-identity: done."
