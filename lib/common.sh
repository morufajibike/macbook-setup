#!/usr/bin/env bash
# lib/common.sh — shared helpers sourced by every numbered script.
# Do not execute directly; source this file.

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

# All log functions write to stderr so they don't pollute stdout pipelines.

info() {
  printf '\033[0;34m[INFO]\033[0m  %s\n' "$*" >&2
}

warn() {
  printf '\033[0;33m[WARN]\033[0m  %s\n' "$*" >&2
}

err() {
  printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2
}

# ---------------------------------------------------------------------------
# Utility predicates
# ---------------------------------------------------------------------------

# Returns 0 if the given command is available on PATH, 1 otherwise.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Repository root resolution
# ---------------------------------------------------------------------------

# Resolves the repository root by walking up from the sourcing script's own
# location. Relies on callers setting BASH_SOURCE correctly, which is always
# true for sourced files.  Do NOT hardcode a path here.
repo_root() {
  # BASH_SOURCE[0] is this file (lib/common.sh); [1] is the calling script.
  # We want the directory that contains lib/, i.e. one level above lib/.
  local this_file
  this_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # lib/ is always one level below the repo root.
  dirname "${this_file}"
}

# ---------------------------------------------------------------------------
# Directory helpers
# ---------------------------------------------------------------------------

# Creates a directory (and any parents) if it does not already exist.
ensure_dir() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    mkdir -p "${dir}"
    info "Created directory: ${dir}"
  fi
}

# ---------------------------------------------------------------------------
# Symlink deployment
# ---------------------------------------------------------------------------

# backup_then_symlink <repo_abs_src> <home_target>
#
# Deploys a dotfile as a symlink, safely backing up any pre-existing file.
#
# Behaviour:
#   1. Ensures the target's parent directory exists.
#   2. If target already exists and is already a correct symlink to src → no-op.
#   3. If target exists (file, wrong symlink, or directory) → backs it up to
#      ~/dotfiles-backup/<basename>.<timestamp> then removes the original.
#   4. Creates the symlink: ln -sfn src target.
backup_then_symlink() {
  local src="$1"
  local target="$2"
  local backup_dir="${HOME}/dotfiles-backup"
  local timestamp
  timestamp="$(date +%Y%m%d_%H%M%S)"

  # Validate source exists.
  if [[ ! -e "${src}" ]]; then
    err "Source does not exist, cannot symlink: ${src}"
    return 1
  fi

  # Ensure the target's parent directory exists.
  ensure_dir "$(dirname "${target}")"

  # If target is already the correct symlink, nothing to do.
  if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${src}" ]]; then
    info "Already linked: ${target} → ${src}"
    return 0
  fi

  # If anything already occupies the target path, back it up.
  if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
    ensure_dir "${backup_dir}"
    local basename
    basename="$(basename "${target}")"
    # The timestamp has only second resolution, so two same-named files backed
    # up in the same second would collide. Append PID + a random suffix, and
    # loop on the off-chance the path still exists, so no backup is clobbered.
    local backup_path
    backup_path="${backup_dir}/${basename}.${timestamp}.$$.${RANDOM}"
    while [[ -e "${backup_path}" ]]; do
      backup_path="${backup_dir}/${basename}.${timestamp}.$$.${RANDOM}"
    done
    warn "Backing up existing ${target} → ${backup_path}"
    mv "${target}" "${backup_path}"
  fi

  ln -sfn "${src}" "${target}"
  info "Linked: ${target} → ${src}"
}
