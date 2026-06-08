#!/usr/bin/env bash
# scripts/20-dotfiles.sh — deploy dotfiles and git-hooks as symlinks.
#
# Every file under dotfiles/ is symlinked into $HOME at the matching relative
# path.  Pre-existing files are backed up to ~/dotfiles-backup/ before the
# symlink is created.  Safe to re-run: already-correct symlinks are no-ops.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

ROOT="$(repo_root)"
DOTFILES_DIR="${ROOT}/dotfiles"

# ---------------------------------------------------------------------------
# Dotfiles — loop over every file (including nested) under dotfiles/
# ---------------------------------------------------------------------------

info "Deploying dotfiles from: ${DOTFILES_DIR}"

# Build a list of all files relative to DOTFILES_DIR.
# We use find with -type f so directories themselves are not symlinked
# individually — only the leaf files are, which is the correct behaviour
# for a sparse dotfiles tree.
#
# find -print0 + read -d '' handles file paths with spaces correctly.
# We strip the DOTFILES_DIR prefix using bash parameter expansion, which
# is safer and more portable than piping through sed.
while IFS= read -r -d '' abs_src; do
  # Strip the leading DOTFILES_DIR path to get the relative path.
  rel_path="${abs_src#"${DOTFILES_DIR}/"}"
  target="${HOME}/${rel_path}"
  backup_then_symlink "${abs_src}" "${target}"
done < <(find "${DOTFILES_DIR}" -type f -print0)

# ---------------------------------------------------------------------------
# git-hooks directory
# ---------------------------------------------------------------------------
# Symlink the whole git-hooks/ directory to ~/.git-hooks so that
# core.hooksPath in .gitconfig points to a live, versioned copy.

# backup_then_symlink already handles directories and derives the backup
# basename, so the same helper used for individual dotfiles applies here.
# Guard against a fresh clone where git-hooks/ was never committed (or was
# dropped by a global core.excludesFile) so the bootstrap does not abort.
if [ -d "${ROOT}/git-hooks" ]; then
  backup_then_symlink "${ROOT}/git-hooks" "${HOME}/.git-hooks"
else
  warn "git-hooks/ not found in the repository — skipping git hooks symlink."
fi

info "20-dotfiles: done."
