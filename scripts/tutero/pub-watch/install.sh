#!/bin/bash
# Installation script for pub-watch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"

echo "Installing pub-watch..."

# Make scripts executable
chmod +x "${SCRIPT_DIR}/pub-watch"
chmod +x "${SCRIPT_DIR}/pub-watch-daemon"

# Create install directory if needed
mkdir -p "$INSTALL_DIR"

# Create symlink
ln -sf "${SCRIPT_DIR}/pub-watch" "${INSTALL_DIR}/pub-watch"

echo "✓ Installed pub-watch to ${INSTALL_DIR}/pub-watch"
echo ""
echo "Usage:"
echo "  pub-watch add <watch-repo> <apply-repo>"
echo "  pub-watch start"
echo "  pub-watch status"
echo ""
echo "Run 'pub-watch --help' for more information."
