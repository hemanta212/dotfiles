#!/bin/bash
# Summary: Installs gh-deliver CLI/daemon into ~/.local/bin and seeds the cache directory.
# Description:
# Ensures ~/.local/bin exists, warns if it is missing from PATH, and makes every script executable.
# Symlinks gh-deliver into ~/.local/bin so the CLI is globally available.
# Creates ~/.cache/scripts/gh-deliver-monitor and bootstraps repos/config/state JSON defaults.
# Prints quick-start steps covering add/start/status/log commands plus how to get help.


# Install script for gh-deliver

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
DATA_DIR="$HOME/.cache/scripts/gh-deliver-monitor"

echo "╔════════════════════════════════════════════════╗"
echo "║  gh-deliver Installation                       ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Create bin directory if it doesn't exist
if [ ! -d "$BIN_DIR" ]; then
    echo "Creating $BIN_DIR..."
    mkdir -p "$BIN_DIR"
fi

# Check if bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "⚠️  Warning: $BIN_DIR is not in your PATH"
    echo "   Add this to your ~/.zshrc or ~/.bashrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$SCRIPT_DIR/gh-deliver"
chmod +x "$SCRIPT_DIR/gh-deliver-daemon"

# Create symlinks
echo "Creating symlinks..."
ln -sf "$SCRIPT_DIR/gh-deliver" "$BIN_DIR/gh-deliver"

# Create data directory
echo "Creating data directory..."
mkdir -p "$DATA_DIR"

# Initialize files if they don't exist
if [ ! -f "$DATA_DIR/repos.json" ]; then
    echo '{"repos": []}' > "$DATA_DIR/repos.json"
fi

if [ ! -f "$DATA_DIR/config.json" ]; then
    cat > "$DATA_DIR/config.json" <<EOF
{
  "check_interval": 300,
  "time_window": "1 hour ago",
  "enable_audio": true,
  "enable_desktop_notif": false,
  "check_limit": 50
}
EOF
fi

if [ ! -f "$DATA_DIR/state.json" ]; then
    echo '{"alerted_runs": {}}' > "$DATA_DIR/state.json"
fi

echo ""
echo "✓ Installation complete!"
echo ""
echo "Quick start:"
echo "  1. Add a repository:     gh-deliver add MathGaps/resources"
echo "  2. Start the daemon:     gh-deliver start"
echo "  3. Check status:         gh-deliver status"
echo "  4. View logs:            gh-deliver logs -f"
echo ""
echo "Get help:                  gh-deliver --help"
echo ""
