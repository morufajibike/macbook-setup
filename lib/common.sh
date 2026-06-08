#!/usr/bin/env bash
# lib/common.sh — shared helpers sourced by every numbered script.
# Do not execute directly; source this file.

# ---------------------------------------------------------------------------
# Dry-run mode
# ---------------------------------------------------------------------------

# Honour DRY_RUN inherited from the environment; default to off.
: "${DRY_RUN:=0}"
export DRY_RUN

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
# run — mutating-command wrapper
# ---------------------------------------------------------------------------

# run <command> [<args>...]
#
# When DRY_RUN=1: prints what would be executed and returns 0 without running.
# When DRY_RUN=0: executes the command exactly as supplied.
#
# Use this for every mutating shell call (git clone, keygen, defaults write,
# brew bundle, etc.).  Read-only commands (command_exists, brew --version,
# pyenv versions --bare, grep, find ...) may be called directly.
run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    # Render each argument safely with printf %q so spaces and special
    # characters are visible and unambiguous.
    local rendered
    rendered="$(printf '%q ' "$@")"
    info "[dry-run] would run: ${rendered% }"
    return 0
  fi
  "$@"
}

# ---------------------------------------------------------------------------
# Utility predicates
# ---------------------------------------------------------------------------

# Returns 0 if the given command is available on PATH, 1 otherwise.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Homebrew PATH bootstrap
# ---------------------------------------------------------------------------

# Ensure Homebrew and its installed tools (pyenv, tmux, node, ...) are on PATH.
# install.sh runs each numbered script as a separate process, so the shellenv
# set in 00-brew.sh does not propagate to siblings; re-establish it here so
# every script can find brew-installed binaries. Read-only PATH setup, so it
# runs in dry-run too (needed for accurate previews on a machine that has brew).
ensure_brew_on_path() {
  if command_exists brew; then
    return 0
  fi
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  # Explicit success: this function is called as a bare statement under set -e,
  # so make the exit status immune to any future trailing-line edit.
  return 0
}

ensure_brew_on_path

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
    run mkdir -p "${dir}"
    if [[ "${DRY_RUN}" != "1" ]]; then
      info "Created directory: ${dir}"
    fi
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
#   2. If target already exists and is already a correct symlink to src -> no-op.
#   3. If target exists (file, wrong symlink, or directory) -> backs it up to
#      ~/dotfiles-backup/<basename>.<timestamp> then removes the original.
#   4. Creates the symlink: ln -sfn src target.
#
# In dry-run mode: logs what would happen and makes no filesystem changes.
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
    info "Already linked: ${target} -> ${src}"
    return 0
  fi

  # If anything already occupies the target path, log the backup intent.
  if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
    local basename
    basename="$(basename "${target}")"
    local backup_path
    backup_path="${backup_dir}/${basename}.${timestamp}.$$.${RANDOM}"

    if [[ "${DRY_RUN}" == "1" ]]; then
      info "[dry-run] would back up ${target} -> ${backup_path}"
    else
      ensure_dir "${backup_dir}"
      # The timestamp has only second resolution, so two same-named files backed
      # up in the same second would collide. Append PID + a random suffix, and
      # loop on the off-chance the path still exists, so no backup is clobbered.
      while [[ -e "${backup_path}" ]]; do
        backup_path="${backup_dir}/${basename}.${timestamp}.$$.${RANDOM}"
      done
      warn "Backing up existing ${target} -> ${backup_path}"
      mv "${target}" "${backup_path}"
    fi
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] would link ${target} -> ${src}"
  else
    ln -sfn "${src}" "${target}"
    info "Linked: ${target} -> ${src}"
  fi
}
