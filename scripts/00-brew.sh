#!/usr/bin/env bash
# scripts/00-brew.sh -- install Homebrew (if absent) and bundle selected groups.
#
# The Brewfile is organised into groups marked by `# group: <name>` lines.
# This script lets you choose which groups to install rather than installing
# everything:
#
#   * Interactive (a TTY on stdin): you are prompted per group. `core` defaults
#     to yes; every other group defaults to no.
#   * Non-interactive (no TTY): the BREW_GROUPS env var selects groups
#     (space- or comma-separated). If BREW_GROUPS is unset, ALL groups are
#     installed (so unattended/CI runs still work) with a warning.
#
# BREW_GROUPS is also honoured on the interactive path: when set it pre-selects
# those groups and skips the prompts. Unknown group names are rejected.
#
#   BREW_GROUPS="core languages" ./install.sh
#
# Dry-run mode (DRY_RUN=1):
#   Homebrew installation is skipped with a log message.
#   Group prompts and Brewfile assembly still run so you can see what WOULD be
#   installed; the assembled Brewfile contents are printed and brew bundle is
#   not executed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

# Known groups, in the order they are prompted / assembled. This is the single
# source of truth for valid group names.
KNOWN_GROUPS=(core cloud-devops languages databases apps)

# ---------------------------------------------------------------------------
# Install Homebrew
# ---------------------------------------------------------------------------

if command_exists brew; then
  info "Homebrew already installed -- skipping install."
elif [[ "${DRY_RUN}" == "1" ]]; then
  info "[dry-run] would install Homebrew via the official install script."
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for the rest of this session, regardless of arch.
# Apple Silicon installs to /opt/homebrew; Intel installs to /usr/local.
# Only attempt this when brew actually exists on disk -- in dry-run on a
# machine without Homebrew there is nothing to eval.
if ! command_exists brew; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Fail fast if brew still cannot be resolved -- every step below depends on it.
# In dry-run mode on a machine without brew we cannot proceed further, but we
# skip the hard exit so the user sees the full preview rather than an error.
if ! command_exists brew; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    warn "brew not on PATH (not yet installed). Brewfile preview continues below."
  else
    err "brew is not on PATH after installation. Cannot continue."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Locate the Brewfile
# ---------------------------------------------------------------------------

BREWFILE="$(repo_root)/Brewfile"

if [[ ! -f "${BREWFILE}" ]]; then
  err "Brewfile not found at: ${BREWFILE}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Group helpers
# ---------------------------------------------------------------------------

# Returns 0 if $1 is one of the KNOWN_GROUPS, 1 otherwise.
is_known_group() {
  local candidate="$1" group
  for group in "${KNOWN_GROUPS[@]}"; do
    [[ "${group}" == "${candidate}" ]] && return 0
  done
  return 1
}

# Counts the install entries (tap/brew/cask lines) in a single group.
# Usage: count_group_entries <group>
count_group_entries() {
  local target="$1" current="" count=0 line trimmed
  while IFS= read -r line; do
    if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]*group:[[:space:]]*(.+)[[:space:]]*$ ]]; then
      # Trim trailing whitespace from the captured group name.
      current="${BASH_REMATCH[1]%"${BASH_REMATCH[1]##*[![:space:]]}"}"
      continue
    fi
    [[ "${current}" != "${target}" ]] && continue
    trimmed="${line#"${line%%[![:space:]]*}"}"
    [[ -z "${trimmed}" || "${trimmed}" == "#"* ]] && continue
    count=$((count + 1))
  done <"${BREWFILE}"
  printf '%s' "${count}"
}

# Emits the install entries for the given groups, in Brewfile order, to stdout.
# Usage: assemble_brewfile <group> [<group> ...]
assemble_brewfile() {
  local -a wanted=("$@")
  local current="" line trimmed group keep
  while IFS= read -r line; do
    if [[ "${line}" =~ ^[[:space:]]*#[[:space:]]*group:[[:space:]]*(.+)[[:space:]]*$ ]]; then
      current="${BASH_REMATCH[1]%"${BASH_REMATCH[1]##*[![:space:]]}"}"
      continue
    fi
    trimmed="${line#"${line%%[![:space:]]*}"}"
    [[ -z "${trimmed}" || "${trimmed}" == "#"* ]] && continue

    keep=0
    for group in "${wanted[@]}"; do
      [[ "${group}" == "${current}" ]] && keep=1 && break
    done
    [[ "${keep}" -eq 1 ]] && printf '%s\n' "${line}"
  done <"${BREWFILE}"
  return 0
}

# Strips the leading `tap`/`brew`/`cask` keyword and the surrounding quotes
# from a Brewfile entry line, leaving just the clean name.
# Usage: strip_entry_name '<keyword> "name" [options...]'
strip_entry_name() {
  local line="$1" name
  # Drop the leading keyword and any whitespace before the opening quote.
  name="${line#* }"
  # Take only what is inside the first pair of double quotes.
  name="${name#\"}"
  name="${name%%\"*}"
  printf '%s' "${name}"
}

# Joins the remaining arguments with ", " (comma + space) onto a single line.
# Bash's "${arr[*]}" only joins on the first character of IFS, so a multi-char
# separator needs an explicit loop.
# Usage: join_comma <item> [<item> ...]
join_comma() {
  local result="" item
  for item in "$@"; do
    if [[ -z "${result}" ]]; then
      result="${item}"
    else
      result="${result}, ${item}"
    fi
  done
  printf '%s' "${result}"
}

# Prints a human-readable listing of a group's entries, broken down by type
# (taps / brews / casks) with keyword + quotes stripped. Only non-empty type
# rows are printed. Written to stdout (the prompt below reads from the TTY, so
# this listing is safe on stdout).
# Usage: list_group_entries <group>
list_group_entries() {
  local target="$1" line keyword name
  local -a taps=() brews=() casks=()

  while IFS= read -r line; do
    keyword="${line%% *}"
    name="$(strip_entry_name "${line}")"
    case "${keyword}" in
    tap) taps+=("${name}") ;;
    brew) brews+=("${name}") ;;
    cask) casks+=("${name}") ;;
    *) : ;; # ignore anything unexpected
    esac
  done < <(assemble_brewfile "${target}")

  [[ "${#taps[@]}" -gt 0 ]] && printf '  taps:  %s\n' "$(join_comma "${taps[@]}")"
  [[ "${#brews[@]}" -gt 0 ]] && printf '  brews: %s\n' "$(join_comma "${brews[@]}")"
  [[ "${#casks[@]}" -gt 0 ]] && printf '  casks: %s\n' "$(join_comma "${casks[@]}")"
  # Return success explicitly: under `set -e`, a final type-row test that is
  # false (e.g. a group with no casks) would otherwise make this function exit
  # non-zero and abort the caller.
  return 0
}

# Validates a list of group names; exits non-zero on the first unknown name.
# Usage: validate_groups <group> [<group> ...]
validate_groups() {
  local group
  for group in "$@"; do
    if ! is_known_group "${group}"; then
      err "Unknown group '${group}'. Valid groups: ${KNOWN_GROUPS[*]}"
      exit 1
    fi
  done
}

# Splits a BREW_GROUPS string (space- or comma-separated) into the global
# SELECTED_GROUPS array.
parse_brew_groups_env() {
  local raw="$1"
  # Normalise commas to spaces, then word-split on whitespace.
  raw="${raw//,/ }"
  # shellcheck disable=SC2206  # deliberate word-splitting of a controlled value
  SELECTED_GROUPS=(${raw})
}

# ---------------------------------------------------------------------------
# Decide which groups to install
# ---------------------------------------------------------------------------

SELECTED_GROUPS=()

if [[ -n "${BREW_GROUPS:-}" ]]; then
  # Explicit selection wins on both interactive and non-interactive paths.
  parse_brew_groups_env "${BREW_GROUPS}"
  validate_groups "${SELECTED_GROUPS[@]}"
  info "Using groups from BREW_GROUPS: ${SELECTED_GROUPS[*]}"
elif [[ ! -t 0 ]]; then
  # Non-interactive and no explicit selection -> install everything so that
  # unattended/CI runs still provision a full machine.
  warn "Non-interactive shell and BREW_GROUPS unset -- installing ALL groups."
  warn "Set BREW_GROUPS (e.g. 'core languages') to install a subset unattended."
  SELECTED_GROUPS=("${KNOWN_GROUPS[@]}")
else
  # Interactive: show each group's contents, then prompt. core defaults to yes;
  # the rest default to no.
  info "Choose which Homebrew groups to install."
  for group in "${KNOWN_GROUPS[@]}"; do
    count="$(count_group_entries "${group}")"
    printf '\nGroup '\''%s'\'' (%s packages):\n' "${group}" "${count}"
    list_group_entries "${group}"
    if [[ "${group}" == "core" ]]; then
      read -r -p "Install group '${group}'? [Y/n]: " reply
      reply="${reply:-y}"
    else
      read -r -p "Install group '${group}'? [y/N]: " reply
      reply="${reply:-n}"
    fi
    case "${reply}" in
    [yY] | [yY][eE][sS]) SELECTED_GROUPS+=("${group}") ;;
    *) : ;; # anything else -> skip this group
    esac
  done
fi

if [[ "${#SELECTED_GROUPS[@]}" -eq 0 ]]; then
  warn "No groups selected -- skipping brew bundle."
fi

# ---------------------------------------------------------------------------
# Assemble a temp Brewfile for the selected groups and bundle it
# ---------------------------------------------------------------------------

if [[ "${#SELECTED_GROUPS[@]}" -gt 0 ]]; then
  TMP_BREWFILE="$(mktemp -t brewfile.XXXXXX)"
  # Ensure the temp file is removed on any exit path.
  trap 'rm -f "${TMP_BREWFILE}"' EXIT

  assemble_brewfile "${SELECTED_GROUPS[@]}" >"${TMP_BREWFILE}"

  total="$(wc -l <"${TMP_BREWFILE}" | tr -d ' ')"

  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] assembled Brewfile for groups: ${SELECTED_GROUPS[*]} (${total} lines)"
    info "[dry-run] Brewfile contents:"
    # Print each line with a leading indent so it is clearly attributed.
    while IFS= read -r line; do
      info "  ${line}"
    done <"${TMP_BREWFILE}"
    info "[dry-run] would run: brew bundle --file=${TMP_BREWFILE}"
  else
    info "Installing ${total} packages across groups: ${SELECTED_GROUPS[*]}"
    brew bundle --file="${TMP_BREWFILE}"
  fi
fi

info "00-brew: done."
