#!/usr/bin/env bash
set -euo pipefail

REPO="tonyxrmdavidson/goswitch"
REF="${1:-v1.0.1}"                 # default release tag; can pass 'main' or another tag
INSTALL_DIR="${HOME}/.goswitch"
BIN="${INSTALL_DIR}/cmd/goswitch"

# Pick a profile file to update PATH (bash or zsh; prefer what's in use)
detect_profile() {
  # Respect ZDOTDIR if present
  if [ -n "${ZDOTDIR:-}" ] && [ -f "${ZDOTDIR}/.zshrc" ]; then echo "${ZDOTDIR}/.zshrc"; return; fi
  # Common shells
  [ -f "${HOME}/.bash_profile" ] && { echo "${HOME}/.bash_profile"; return; }
  [ -f "${HOME}/.bashrc" ] && { echo "${HOME}/.bashrc"; return; }
  [ -f "${HOME}/.zshrc" ] && { echo "${HOME}/.zshrc"; return; }
  # Fallback create .bash_profile
  echo "${HOME}/.bash_profile"
}

PROFILE="$(detect_profile)"

echo "→ Installing goswitch (${REF}) to ${INSTALL_DIR}"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Resolve archive URL (tag or branch)
URL="https://github.com/${REPO}/archive/refs/tags/${REF}.tar.gz"
case "$REF" in
  v*|[0-9]*.[0-9]*.[0-9]*) : ;;
  *) URL="https://github.com/${REPO}/archive/refs/heads/${REF}.tar.gz" ;;
esac

echo "→ Downloading ${URL}"
curl -fsSL "$URL" -o "${tmp}/src.tgz"

echo "→ Extracting"
tar -xzf "${tmp}/src.tgz" -C "$tmp"
SRC_DIR="$(find "$tmp" -maxdepth 1 -type d -name 'goswitch-*' | head -n1)"

echo "→ Syncing files to ${INSTALL_DIR}"
mkdir -p "$INSTALL_DIR"
rsync -a --delete "${SRC_DIR}/" "${INSTALL_DIR}/"

echo "→ Ensuring executable"
chmod +x "$BIN"

# Ensure PATH has ~/.goswitch/cmd
LINE='export PATH="$HOME/.goswitch/cmd:$PATH"'
if ! grep -Fq "$LINE" "$PROFILE" 2>/dev/null; then
  echo "$LINE" >> "$PROFILE"
  ADDED_PATH=1
else
  ADDED_PATH=0
fi

# Optional: on macOS, ensure Homebrew env is evaluated (helps PATH order)
if [ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "darwin" ] && command -v brew >/dev/null 2>&1; then
  BREW_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
  if ! grep -Fq "$BREW_LINE" "$PROFILE" 2>/dev/null; then
    echo "$BREW_LINE" >> "$PROFILE"
    ADDED_BREW=1
  else
    ADDED_BREW=0
  fi
fi

# --- asdf integration (one-time): make Go shim delegate to system ---
# This lets goswitch control the active Go outside repos with a local .tool-versions
if command -v asdf >/dev/null 2>&1; then
  echo "→ Configuring asdf to use 'system' Go by default (so goswitch can manage Homebrew/tarball Go)..."
  # Ensure plugin present
  if ! asdf plugin list 2>/dev/null | grep -qx 'golang'; then
    asdf plugin add golang >/dev/null 2>&1 || true
  fi
  # Set global to system if not already set
  CURRENT_G="$(asdf global golang 2>/dev/null || true)"
  if ! echo "$CURRENT_G" | grep -q 'system'; then
    asdf global golang system >/dev/null 2>&1 || true
  fi
  # Reshim to refresh shims
  asdf reshim golang >/dev/null 2>&1 || true
fi

# Try to make it immediately available in this shell (best-effort)
# shellcheck disable=SC1090
source "$PROFILE" 2>/dev/null || true

echo "→ Verifying"
if command -v goswitch >/dev/null 2>&1; then
  "$BIN" --version || true
  echo "✅ Installed goswitch to ${BIN}"
else
  echo "⚠️  'goswitch' not found on PATH yet."
  echo "   Add to PATH if needed: ${LINE}"
fi

if [ "${ADDED_PATH:-0}" -eq 1 ] || [ "${ADDED_BREW:-0}" -eq 1 ]; then
  echo "ℹ️  Profile updated: ${PROFILE}"
  echo "   Open a new shell or run:  source \"${PROFILE}\""
fi

echo "Done."
