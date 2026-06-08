#!/usr/bin/env bash
# scripts/50-python.sh -- install a pinned Python version via pyenv.
#
# pyenv itself is installed by Homebrew (00-brew.sh).  This script installs
# the pinned application-level Python version and sets it as the global
# default.  The operation is idempotent: if the version is already installed
# it is not reinstalled.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../lib
source "${SCRIPT_DIR}/../lib/common.sh"

# The Python version to pin.  Change here to update the whole machine.
#
# NOTE: `pyenv install` compiles CPython from source and therefore needs the
# build dependencies present (openssl, readline, xz, zlib, etc.) plus the Xcode
# Command Line Tools. A modern Python builds cleanly against the OpenSSL that
# Homebrew pulls in as a dependency (openssl@3). If `pyenv install` fails on a
# fresh machine, bump this pinned version to a release that builds cleanly on
# the current toolchain.
PYTHON_VERSION="3.13.11"

# ---------------------------------------------------------------------------
# Ensure pyenv is available
# ---------------------------------------------------------------------------

if ! command_exists pyenv; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    info "[dry-run] pyenv is not installed yet (00-brew would install it); skipping Python setup preview."
    exit 0
  fi
  err "pyenv not found. Ensure 00-brew.sh ran and its packages are on PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# Install the pinned Python version
# ---------------------------------------------------------------------------

if pyenv versions --bare | grep -qxF "${PYTHON_VERSION}"; then
  info "Python ${PYTHON_VERSION} already installed via pyenv -- skipping."
else
  info "Installing Python ${PYTHON_VERSION} via pyenv..."
  run pyenv install "${PYTHON_VERSION}"
fi

# ---------------------------------------------------------------------------
# Set as global default
# ---------------------------------------------------------------------------

CURRENT_GLOBAL="$(pyenv global)"

if [[ "${CURRENT_GLOBAL}" == "${PYTHON_VERSION}" ]]; then
  info "pyenv global is already ${PYTHON_VERSION} -- no change."
else
  info "Setting pyenv global to ${PYTHON_VERSION}..."
  run pyenv global "${PYTHON_VERSION}"
fi

# ---------------------------------------------------------------------------
# Common pip packages
# ---------------------------------------------------------------------------

info "Installing common pip packages..."
# Use the pyenv-managed pip to avoid polluting the system Python.
run "$(pyenv root)/versions/${PYTHON_VERSION}/bin/pip" install --upgrade \
  flake8 \
  ipython \
  pytest

info "50-python: done."
