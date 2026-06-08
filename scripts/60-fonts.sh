#!/usr/bin/env bash
# scripts/60-fonts.sh — install programming fonts not delivered via Homebrew.
#
# Meslo Nerd Font is installed by the Brewfile (font-meslo-lg-nerd-font cask)
# so it is NOT downloaded here.  This script handles fonts that are not
# available as Homebrew casks: FiraCode, Operator Mono, and Powerline fonts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

ROOT="$(repo_root)"
FONTS_WORK_DIR="${ROOT}/.fonts-work"

ensure_dir "${FONTS_WORK_DIR}"

# ---------------------------------------------------------------------------
# FiraCode
# ---------------------------------------------------------------------------

FIRACODE_DIR="${FONTS_WORK_DIR}/FiraCode"

if [[ -d "${FIRACODE_DIR}" ]]; then
  info "FiraCode already cloned — skipping."
else
  info "Cloning FiraCode..."
  git clone --depth=1 \
    https://github.com/tonsky/FiraCode.git \
    "${FIRACODE_DIR}"
fi

FIRACODE_FONT_DIR="${HOME}/Library/Fonts/FiraCode"
if [[ -d "${FIRACODE_FONT_DIR}" ]]; then
  info "FiraCode fonts already installed — skipping."
else
  info "Installing FiraCode fonts..."
  ensure_dir "${FIRACODE_FONT_DIR}"
  cp "${FIRACODE_DIR}"/ttf/*.ttf "${FIRACODE_FONT_DIR}/"
fi

# ---------------------------------------------------------------------------
# Powerline fonts
# ---------------------------------------------------------------------------

POWERLINE_DIR="${FONTS_WORK_DIR}/powerline-fonts"

if [[ -d "${POWERLINE_DIR}" ]]; then
  info "Powerline fonts already cloned — skipping clone."
else
  info "Cloning Powerline fonts..."
  git clone --depth=1 \
    https://github.com/powerline/fonts.git \
    "${POWERLINE_DIR}"
fi

# The install.sh script is idempotent (it copies to ~/Library/Fonts).
info "Installing Powerline fonts..."
bash "${POWERLINE_DIR}/install.sh"

# ---------------------------------------------------------------------------
# Operator Mono (ligaturised variant)
# ---------------------------------------------------------------------------
# Operator Mono is a commercial font; we only clone the ligature-builder repo
# and expect the user to supply the original OTF files at
# $FONTS_WORK_DIR/operator-mono-lig/original/. If they are absent we skip.

OPERATOR_DIR="${FONTS_WORK_DIR}/operator-mono-lig"

if [[ -d "${OPERATOR_DIR}" ]]; then
  info "operator-mono-lig already cloned — skipping."
else
  info "Cloning operator-mono-lig builder..."
  git clone --depth=1 \
    https://github.com/kiliman/operator-mono-lig.git \
    "${OPERATOR_DIR}"
fi

if [[ -d "${OPERATOR_DIR}/original" ]] &&
  [[ -n "$(ls -A "${OPERATOR_DIR}/original" 2>/dev/null)" ]]; then
  # The ligature builder needs Node/npm. Guard it so a missing npm cannot
  # abort the whole bootstrap under `set -e`.
  if ! command_exists npm; then
    warn "npm not found — skipping Operator Mono ligature build (install Node and re-run)."
  else
    info "Building Operator Mono ligature variant..."
    # fonttools is required; install via pip if missing.
    if ! command_exists python3 || ! python3 -c "import fonttools" 2>/dev/null; then
      pip3 install --quiet fonttools
    fi
    (
      cd "${OPERATOR_DIR}"
      npm install --silent
      bash build.sh
    )
  fi
else
  warn "Operator Mono source fonts not found in ${OPERATOR_DIR}/original — skipping build."
  warn "Place the original .otf files there and re-run this script to build the ligature variant."
fi

info "60-fonts: done."
