#!/usr/bin/env bash
# scripts/70-ssh.sh — create a GitHub SSH key if one does not already exist.
#
# Idempotent: if ~/.ssh/id_ed25519_github already exists the script exits early.
# Git identity (name/email) is managed via dotfiles/.gitconfig — it is NOT
# set here to avoid coupling this script to a specific user identity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

SSH_KEY="${HOME}/.ssh/id_ed25519_github"
SSH_CONFIG="${HOME}/.ssh/config"

# ---------------------------------------------------------------------------
# Skip if key already exists
# ---------------------------------------------------------------------------

if [[ -f "${SSH_KEY}" ]]; then
  info "SSH key ${SSH_KEY} already exists — skipping generation."
  exit 0
fi

# ---------------------------------------------------------------------------
# Determine the key comment from git config (graceful fallback)
# ---------------------------------------------------------------------------

KEY_COMMENT=""
if command_exists git; then
  KEY_COMMENT="$(git config --global user.email 2>/dev/null || true)"
fi

# Fall back to a generic, machine-identifying comment if no git email is set
# (e.g. identity was skipped in a non-interactive run). This keeps key
# generation from ever breaking on an empty comment.
if [[ -z "${KEY_COMMENT}" ]]; then
  KEY_COMMENT="${USER}@$(hostname)"
fi

# ---------------------------------------------------------------------------
# Generate the key
# ---------------------------------------------------------------------------

info "Generating GitHub SSH key: ${SSH_KEY}"
ensure_dir "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Ed25519 is the modern recommended key type: smaller, faster, and as strong
# as RSA-4096.
#
# -N "" creates the key with an EMPTY passphrase. This is a deliberate choice
# for unattended bootstrap so the run does not block on a prompt. If you
# prefer a passphrase-protected key, remove -N "" (ssh-keygen will then prompt)
# or supply one explicitly.
ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${SSH_KEY}" -N ""

# ---------------------------------------------------------------------------
# Start the ssh-agent and add the key
# ---------------------------------------------------------------------------

eval "$(ssh-agent -s)"

# -K stores the passphrase in the macOS Keychain (valid for empty passphrase
# on macOS 12+; ignored harmlessly on older versions).
ssh-add --apple-use-keychain "${SSH_KEY}" 2>/dev/null ||
  ssh-add "${SSH_KEY}"

# ---------------------------------------------------------------------------
# Append the GitHub host block to ~/.ssh/config (idempotent)
# ---------------------------------------------------------------------------

SSH_BLOCK="Host github.com
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ${SSH_KEY}"

if grep -qF "IdentityFile ${SSH_KEY}" "${SSH_CONFIG}" 2>/dev/null; then
  info "SSH config already contains entry for ${SSH_KEY} — skipping."
else
  info "Appending GitHub host block to ${SSH_CONFIG}..."
  touch "${SSH_CONFIG}"
  chmod 600 "${SSH_CONFIG}"
  printf '\n%s\n' "${SSH_BLOCK}" >>"${SSH_CONFIG}"
fi

# ---------------------------------------------------------------------------
# Print the public key so the user can add it to GitHub
# ---------------------------------------------------------------------------

printf '\n'
info "SSH key generation complete."
info "Add the following public key to https://github.com/settings/keys:"
printf '\n'
cat "${SSH_KEY}.pub"
printf '\n'

info "70-ssh: done."
