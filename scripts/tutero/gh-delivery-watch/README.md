# gh-deliver - GitHub Delivery Workflow Monitor

A long-running service that monitors GitHub Actions "Delivery" workflows and alerts you when builds fail using audio (piper-say/say) and desktop notifications.

## Features

✅ **Add/Remove Repos** - Easy CLI to manage monitored repositories  
🔊 **Audio Alerts** - Speaks failure messages with piper-say or macOS say  
📊 **Per-Repo Tracking** - Individual workflow filters and failure counts  
💾 **Persistent State** - Prevents duplicate alerts, survives restarts  
🔄 **Hot Reload** - Update config without restarting daemon  
📝 **Comprehensive Logging** - All activity logged to file  
⚡ **Lightweight** - Runs in background, minimal resource usage  

## Installation

```bash
cd ~/dev/dotfiles/scripts/tutero/gh-delivery-watch
./install.sh
```

This will:
- Make scripts executable
- Create symlink: `~/.local/bin/gh-deliver`
- Initialize data directory: `~/.cache/scripts/gh-deliver-monitor/`

## Quick Start

```bash
# 1. Add repositories to monitor
gh-deliver add MathGaps/resources
gh-deliver add MathGaps/schools-app

# 2. List monitored repos
gh-deliver list

# 3. Start the daemon
gh-deliver start

# 4. Check status
gh-deliver status

# 5. Watch logs (live)
gh-deliver logs -f
```

## Commands

### Repository Management

```bash
# Add a repo (default workflow: "Delivery")
gh-deliver add owner/repo

# Add with custom workflow filter
gh-deliver add owner/repo "^(Delivery|Deploy)"

# Remove a repo
gh-deliver remove owner/repo

# List all monitored repos
gh-deliver list

# Enable/disable monitoring for a repo
gh-deliver enable owner/repo
gh-deliver disable owner/repo
```

### Daemon Control

```bash
# Start the background daemon
gh-deliver start

# Stop the daemon
gh-deliver stop

# Restart the daemon
gh-deliver restart

# Reload config without restart
gh-deliver reload

# Check daemon status
gh-deliver status
```

### Configuration

```bash
# Show current config
gh-deliver config

# Set config values
gh-deliver config set check_interval 300        # seconds
gh-deliver config set time_window "1 hour ago"
gh-deliver config set enable_audio true
gh-deliver config set enable_desktop_notif true
gh-deliver config set check_limit 50            # runs to check per repo
```

Available config keys:
- `check_interval` - Seconds between checks (default: 300 = 5 minutes)
- `time_window` - How far back to look (e.g., "1 hour ago", "30 minutes ago")
- `enable_audio` - Enable audio alerts with piper-say/say (default: true)
- `enable_desktop_notif` - Enable macOS notifications (default: false)
- `check_limit` - Max workflow runs to check per repo (default: 50)

### Utilities

```bash
# Run a single check (no daemon)
gh-deliver check

# View logs
gh-deliver logs           # Show all logs
gh-deliver logs -f        # Follow logs (live)

# Reset alert state (re-alert for all failures)
gh-deliver reset
```

## File Locations

All data is stored in `~/.cache/scripts/gh-deliver-monitor/`:

```
~/.cache/scripts/gh-deliver-monitor/
├── repos.json        # Monitored repositories
├── config.json       # Configuration
├── state.json        # Alert state (prevents duplicates)
├── daemon.log        # Daemon logs
└── daemon.pid        # Daemon process ID
```

Source files are in:
```
~/dev/dotfiles/scripts/tutero/gh-delivery-watch/
├── gh-deliver         # Main CLI command
├── gh-deliver-daemon  # Background service
├── install.sh         # Installation script
└── README.md          # This file
```

## How It Works

1. **Daemon runs in background**, checking repositories every N minutes
2. **Queries GitHub Actions** via `gh run list` for recent workflow runs
3. **Filters workflows** by name (e.g., "Delivery")
4. **Detects failures** (failure, cancelled, timed_out conclusions)
5. **Checks state file** to prevent duplicate alerts
6. **Sends alerts**:
   - 🔊 Audio via piper-say or say
   - 🔔 macOS desktop notification (if enabled)
   - 📝 Logs to file
7. **Updates metadata**: last check time, failure counts
8. **Marks as alerted** so you don't get notified again

## Examples

### Monitor multiple repos with different workflows

```bash
gh-deliver add MathGaps/resources Delivery
gh-deliver add MathGaps/backend "^(Deploy|Release)"
gh-deliver add myorg/frontend "Integration"
```

### Fast checking (every 2 minutes, look back 5 minutes)

```bash
gh-deliver config set check_interval 120
gh-deliver config set time_window "5 minutes ago"
gh-deliver restart
```

### Longer window (check every 10 min, look back 30 min)

```bash
gh-deliver config set check_interval 600
gh-deliver config set time_window "30 minutes ago"
gh-deliver restart
```

### Audio + Desktop notifications

```bash
gh-deliver config set enable_audio true
gh-deliver config set enable_desktop_notif true
gh-deliver reload
```

### Temporarily disable a repo

```bash
gh-deliver disable MathGaps/schools-app
# ... later ...
gh-deliver enable MathGaps/schools-app
```

## Prerequisites

- **GitHub CLI** (`gh`) - installed and authenticated
  ```bash
  brew install gh
  gh auth login
  ```

- **jq** - JSON processor
  ```bash
  brew install jq
  ```

- **piper-say** or **say** (macOS) - for audio alerts
  - macOS: `say` is built-in
  - piper-say: https://github.com/rhasspy/piper

## Audio Alerts

When a Delivery build fails, you'll hear:
> "Alert! Delivery build failed for resources on branch v1.0.0-rc.713"

The daemon uses:
1. `piper-say` if available (faster, better quality)
2. Falls back to `say` on macOS
3. Silently skips if neither is available

Disable audio:
```bash
gh-deliver config set enable_audio false
```

## Troubleshooting

### Daemon won't start

```bash
# Check if repos are added
gh-deliver list

# Check logs for errors
gh-deliver logs

# Try running a single check
gh-deliver check
```

### No alerts appearing

```bash
# Check time window (maybe looking too far back)
gh-deliver config

# Try longer window
gh-deliver config set time_window "24 hours ago"

# Reset state to re-alert
gh-deliver reset

# Run single check to test
gh-deliver check
```

### Audio not working

```bash
# Test piper-say or say
piper-say "test"
# or
say "test"

# Check config
gh-deliver config

# Enable audio if disabled
gh-deliver config set enable_audio true
```

### Daemon seems stuck

```bash
# Check status
gh-deliver status

# View logs
gh-deliver logs -f

# Restart
gh-deliver restart
```

### Remove all monitored repos

```bash
gh-deliver remove MathGaps/resources
gh-deliver remove MathGaps/schools-app
# ... or manually:
echo '{"repos": []}' > ~/.cache/scripts/gh-deliver-monitor/repos.json
```

## Development

### Run in foreground (debug mode)

```bash
~/dev/dotfiles/scripts/tutero/gh-delivery-watch/gh-deliver-daemon --once
```

### Watch logs in real-time

```bash
tail -f ~/.cache/scripts/gh-deliver-monitor/daemon.log
```

### Inspect data files

```bash
cat ~/.cache/scripts/gh-deliver-monitor/repos.json | jq .
cat ~/.cache/scripts/gh-deliver-monitor/state.json | jq .
cat ~/.cache/scripts/gh-deliver-monitor/config.json | jq .
```

## Uninstall

```bash
# Stop daemon
gh-deliver stop

# Remove symlink
rm ~/.local/bin/gh-deliver

# Remove data (optional)
rm -rf ~/.cache/scripts/gh-deliver-monitor

# Remove source (optional)
rm -rf ~/dev/dotfiles/scripts/tutero/gh-delivery-watch
```

## Architecture

```
gh-deliver (CLI)
    ├── Manages repos.json
    ├── Controls daemon
    └── Spawns gh-deliver-daemon

gh-deliver-daemon (Service)
    ├── Loads repos + config
    ├── Runs check loop
    ├── Queries GitHub (gh run list)
    ├── Detects failures
    ├── Sends alerts
    ├── Updates state
    └── Handles reload signals
```

## License

MIT
