#!/usr/bin/env bash
# scripts/70-ssh.sh -- ensure an SSH key exists for GitHub access.
#
# Behaviour:
#   1. If a recognised private SSH key already exists in ~/.ssh/, reuse it:
#      skip keygen but still add it to the ssh-agent and ensure the github.com
#      host block in ~/.ssh/config references it. Candidates are considered in
#      a fixed strength-ordered preference list (strongest / most modern
#      first):
#          id_ed25519, id_ed25519_sk, id_ed25519_github,
#          id_ecdsa_sk,  id_ecdsa,
#          id_rsa
#      DSA keys (id_dsa) are explicitly NOT considered -- they are deprecated
#      and unsafe. A candidate must be a readable regular file whose basename
#      matches ^[A-Za-z0-9_.-]+$ and does not end in .pub / -cert / .bak /
#      .old / ~. It must also parse as a valid private key via
#      `ssh-keygen -y -f <path> </dev/null`; passphrase-protected keys will
#      fail that check without prompting and are still accepted for reuse
#      (they simply cannot have their public half derived on the fly).
#   2. Otherwise generate a new Ed25519 key at ~/.ssh/id_ed25519_github and
#      run the same agent-add + config-append steps.
#
# Both the agent-add and the ~/.ssh/config append are idempotent, so this
# script is safe to re-run.
#
# Git identity (name/email) is managed via dotfiles/.gitconfig -- it is NOT
# set here to avoid coupling this script to a specific user identity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

DEFAULT_SSH_KEY="${HOME}/.ssh/id_ed25519_github"
SSH_CONFIG="${HOME}/.ssh/config"

# Always ensure ~/.ssh exists with correct permissions before any file work.
# This runs unconditionally so both the reuse and generate paths benefit.
ensure_dir "${HOME}/.ssh"
run chmod 700 "${HOME}/.ssh"

# ---------------------------------------------------------------------------
# Reuse any existing private key, or fall through to generation
# ---------------------------------------------------------------------------
#
# Strength-ordered allow-list. Anything not on this list is ignored, which
# prevents unrelated keys (e.g. per-service identities the user does not want
# repurposed for GitHub) from being silently reused.

SSH_KEY_CANDIDATES=(
  id_ed25519
  id_ed25519_sk
  id_ed25519_github
  id_ecdsa_sk
  id_ecdsa
  id_rsa
)

# Basename must be pure filename-safe characters. Anything else is a red flag
# -- possibly a filename crafted to inject into ~/.ssh/config -- and is
# skipped with a warning.
SSH_KEY_BASENAME_RE='^[A-Za-z0-9_.-]+$'

SSH_KEY=""
SKIP_KEYGEN=0

# Iterate the explicit allow-list -- no glob expansion involved, so no
# nullglob handling is required.
for basename in "${SSH_KEY_CANDIDATES[@]}"; do
  candidate="${HOME}/.ssh/${basename}"

  # Fast structural checks first.
  [[ -f "${candidate}" && -r "${candidate}" ]] || continue

  # Defence in depth: even though basenames are hard-coded, sanitise before
  # any downstream interpolation (e.g. into ~/.ssh/config).
  if [[ ! "${basename}" =~ ${SSH_KEY_BASENAME_RE} ]]; then
    warn "Ignoring candidate with unsafe basename: ${basename}"
    continue
  fi

  # Reject sidecar / backup filenames defensively.
  case "${basename}" in
    *.pub | *-cert | *.bak | *.old | *~)
      continue
      ;;
  esac

  # Validate that it parses as a private key. Redirecting stdin from
  # /dev/null neutralises the interactive passphrase prompt: for a
  # passphrase-protected key ssh-keygen will fail immediately rather than
  # blocking. We accept both outcomes (0 = definitely valid; non-zero = still
  # potentially reusable, e.g. passphrase-protected) but log the ambiguous
  # case so the operator knows what happened.
  if ssh-keygen -y -f "${candidate}" </dev/null >/dev/null 2>&1; then
    SSH_KEY="${candidate}"
    SKIP_KEYGEN=1
    break
  fi

  # Non-zero exit: could be passphrase-protected (fine, reuse) or genuinely
  # malformed (not fine). Accept it if the .pub sidecar exists, because that
  # is strong evidence it is a real key; otherwise skip with a warning.
  if [[ -f "${candidate}.pub" ]]; then
    warn "Reusing ${candidate} (passphrase-protected or ssh-keygen could not derive its public half)."
    SSH_KEY="${candidate}"
    SKIP_KEYGEN=1
    break
  fi

  warn "Skipping ${candidate}: ssh-keygen could not validate it and no .pub sidecar is present."
done

if [[ "${SKIP_KEYGEN}" == "1" ]]; then
  info "Existing SSH private key found at ${SSH_KEY} -- skipping generation."
else
  SSH_KEY="${DEFAULT_SSH_KEY}"
fi

# ---------------------------------------------------------------------------
# Generate the key (only if no existing private key was discovered)
# ---------------------------------------------------------------------------

if [[ "${SKIP_KEYGEN}" != "1" ]]; then
  info "Generating GitHub SSH key: ${SSH_KEY}"

  # Compute the key comment lazily -- it is only used by `ssh-keygen -C`, so
  # we avoid running `git`, `hostname`, etc. on the reuse path.
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

  # Ed25519 is the modern recommended key type: smaller, faster, and as strong
  # as RSA-4096.
  #
  # -N "" creates the key with an EMPTY passphrase. This is a deliberate choice
  # for unattended bootstrap so the run does not block on a prompt. If you
  # prefer a passphrase-protected key, remove -N "" (ssh-keygen will then prompt)
  # or supply one explicitly.
  run ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${SSH_KEY}" -N ""
fi

# ---------------------------------------------------------------------------
# Enforce permissions on the resolved key (applies to both reuse and generate)
# ---------------------------------------------------------------------------

if [[ -f "${SSH_KEY}" ]]; then
  run chmod 600 "${SSH_KEY}"
fi
if [[ -f "${SSH_KEY}.pub" ]]; then
  run chmod 644 "${SSH_KEY}.pub"
fi

# ---------------------------------------------------------------------------
# Start the ssh-agent and add the key
# ---------------------------------------------------------------------------

if [[ "${DRY_RUN}" == "1" ]]; then
  info "[dry-run] would eval \$(ssh-agent -s) and add ${SSH_KEY} to the agent."
else
  eval "$(ssh-agent -s)"

  # --apple-use-keychain stores the passphrase in the macOS Keychain (the
  # modern replacement for -K on macOS 12+); the fallback ssh-add handles
  # older or non-Apple builds where the flag is unknown.
  ssh-add --apple-use-keychain "${SSH_KEY}" 2>/dev/null ||
    ssh-add "${SSH_KEY}"
fi

# ---------------------------------------------------------------------------
# Append the GitHub host block to ~/.ssh/config (idempotent)
# ---------------------------------------------------------------------------

SSH_BLOCK="Host github.com
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ${SSH_KEY}"

# Match on the exact `IdentityFile <path>` field pair rather than a substring:
# `grep -F "IdentityFile ${SSH_KEY}"` would false-positive when SSH_KEY is a
# prefix of another key path (e.g. id_ed25519 vs id_ed25519_github). awk
# tokenises on whitespace, so $1/$2 give us anchored field equality without
# regex-escaping the path.
if awk -v k="${SSH_KEY}" '
    $1=="IdentityFile" && $2==k { found=1; exit }
    END { exit !found }
' "${SSH_CONFIG}" 2>/dev/null; then
  info "SSH config already contains entry for ${SSH_KEY} -- skipping."
elif [[ "${DRY_RUN}" == "1" ]]; then
  info "[dry-run] would append GitHub host block for ${SSH_KEY} to ${SSH_CONFIG}"
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
if [[ "${SKIP_KEYGEN}" == "1" ]]; then
  info "Reusing existing SSH key: ${SSH_KEY}"
else
  info "SSH key generation complete."
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  info "[dry-run] would print the public key at ${SSH_KEY}.pub for you to register at https://github.com/settings/keys"
else
  info "Ensure the following public key is registered at https://github.com/settings/keys:"
  printf '\n'
  if [[ -f "${SSH_KEY}.pub" ]]; then
    cat "${SSH_KEY}.pub"
  else
    # Derive the public key from the private key if the .pub sidecar is missing
    # (common when reusing a key that was imported without its public half).
    # Redirect stdin from /dev/null so ssh-keygen fails fast on a
    # passphrase-protected key instead of dropping into an interactive prompt.
    if ! ssh-keygen -y -f "${SSH_KEY}" </dev/null 2>/dev/null; then
      warn "Could not read public key for ${SSH_KEY} (passphrase-protected or unreadable); add it to GitHub manually."
    fi
  fi
  printf '\n'
fi

info "70-ssh: done."
