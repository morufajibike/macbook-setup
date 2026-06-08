#!/usr/bin/env bash
# scripts/50-python.sh — install a pinned Python version via pyenv.
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
# build dependencies present (openssl, readline, xz, zlib, etc.). These come
# from the Brewfile (openssl@1.1) plus the Xcode Command Line Tools. Building
# an older release such as 3.9.6 can fail on a modern toolchain (newer clang
# or OpenSSL 3.x). If `pyenv install` fails on a fresh machine, bump this
# pinned version to a release that builds cleanly on the current toolchain.
PYTHON_VERSION="3.9.6"

# ---------------------------------------------------------------------------
# Ensure pyenv is available
# ---------------------------------------------------------------------------

if ! command_exists pyenv; then
  err "pyenv not found. Ensure 00-brew.sh ran successfully."
  exit 1
fi

# ---------------------------------------------------------------------------
# Install the pinned Python version
# ---------------------------------------------------------------------------

if pyenv versions --bare | grep -qxF "${PYTHON_VERSION}"; then
  info "Python ${PYTHON_VERSION} already installed via pyenv — skipping."
else
  info "Installing Python ${PYTHON_VERSION} via pyenv..."
  pyenv install "${PYTHON_VERSION}"
fi

# ---------------------------------------------------------------------------
# Set as global default
# ---------------------------------------------------------------------------

CURRENT_GLOBAL="$(pyenv global)"

if [[ "${CURRENT_GLOBAL}" == "${PYTHON_VERSION}" ]]; then
  info "pyenv global is already ${PYTHON_VERSION} — no change."
else
  info "Setting pyenv global to ${PYTHON_VERSION}..."
  pyenv global "${PYTHON_VERSION}"
fi

# ---------------------------------------------------------------------------
# Common pip packages
# ---------------------------------------------------------------------------

info "Installing common pip packages..."
# Use the pyenv-managed pip to avoid polluting the system Python.
"$(pyenv root)/versions/${PYTHON_VERSION}/bin/pip" install --upgrade \
  flake8 \
  ipython \
  pytest

info "50-python: done."
