#!/usr/bin/env bash
# scripts/80-macos.sh -- curated, reversible macOS system defaults.
#
# Every `defaults write` call here is documented so you can understand and
# tune it.  To revert any setting, use `defaults delete <domain> <key>` or
# set it back to the system default via System Settings.
#
# Note: some changes require re-login or a full restart to take effect
# beyond the `killall` calls at the bottom.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

info "Applying macOS system defaults..."

# ---------------------------------------------------------------------------
# Finder
# ---------------------------------------------------------------------------

# Show all filename extensions (e.g. "document.pdf" not "document").
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files in Finder (dotfiles, /etc, etc.).
run defaults write com.apple.finder AppleShowAllFiles -bool true

# Show the path bar at the bottom of Finder windows.
run defaults write com.apple.finder ShowPathbar -bool true

# Show the status bar at the bottom of Finder windows (item count, disk space).
run defaults write com.apple.finder ShowStatusBar -bool true

# ---------------------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------------------

# Set a fast key-repeat rate.
# Lower values = faster; macOS default is 6 (approx. 90ms between repeats).
run defaults write NSGlobalDomain KeyRepeat -int 2

# Reduce the delay before key repeat starts.
# Lower values = shorter delay; macOS default is 68 (approx. 680ms).
run defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accented character picker; use key repeat instead.
run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ---------------------------------------------------------------------------
# Save and print panels
# ---------------------------------------------------------------------------

# Expand the Save panel by default (show all options, not the collapsed view).
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand the Print panel by default.
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# ---------------------------------------------------------------------------
# Storage -- avoid .DS_Store pollution
# ---------------------------------------------------------------------------

# Do not create .DS_Store files on network volumes.
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Do not create .DS_Store files on USB volumes.
run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------

# Require password immediately after screen saver begins or display sleeps.
run defaults write com.apple.screensaver askForPassword -int 1
run defaults write com.apple.screensaver askForPasswordDelay -int 0

# ---------------------------------------------------------------------------
# Restart affected system processes
# ---------------------------------------------------------------------------
# `killall` exits non-zero if the process is not running; the `run` wrapper
# executes the command as-is (the caller adds `|| true` when invoking directly;
# here we guard per-call so dry-run still shows intent).

info "Restarting Finder, Dock, and SystemUIServer to apply changes..."
run killall Finder || true
run killall Dock || true
run killall SystemUIServer || true

info "80-macos: done."
info "Some settings (e.g. keyboard repeat) may require logging out and back in."
