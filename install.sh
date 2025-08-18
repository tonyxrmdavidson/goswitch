#!/usr/bin/env bash
set -euo pipefail

REPO="tonyxrmdavidson/goswitch"
VERSION="${VERSION:-latest}"

# Detect OS + Arch
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64 | arm64) ARCH="arm64" ;;
esac

# Figure out latest release or specific version
if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -Po '"tag_name": "\K.*?(?=")')
fi

TARBALL="goswitch_${VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$TARBALL"

echo "Downloading $URL..."
curl -fsSL -o "$TARBALL" "$URL"

echo "Installing goswitch..."
tar -xzf "$TARBALL"
chmod +x goswitch

# Move to ~/.local/bin or /usr/local/bin
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"
mv goswitch "$INSTALL_DIR/"

echo "✅ Installed goswitch to $INSTALL_DIR"
echo "Make sure $INSTALL_DIR is in your PATH!"
