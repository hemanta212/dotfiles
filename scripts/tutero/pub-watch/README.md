# pub-watch - Package Update Auto-PR Tool

Monitors GitHub repositories for merged commits from specific authors, detects release metadata updates, queries private pub server for package hashes, updates `pubspec.lock` files, validates builds, and creates pull requests automatically.

## Installation

```bash
cd ~/dev/dotfiles/scripts/tutero/pub-watch
./install.sh
```

Creates symlink: `~/.local/bin/pub-watch`

## Quick Start

```bash
# Add repository pair to watch
pub-watch add hemanta212/learning-library hemanta212/schools-app

# Start daemon
pub-watch start

# Check status
pub-watch status

# View logs
pub-watch logs -f
```

## Commands

### Repository Management
```bash
pub-watch add <watch-owner/repo> <apply-owner/repo>  # Add watch pair
pub-watch remove <watch-owner/repo>                   # Remove watch
pub-watch list                                        # List all watches
```

### Daemon Control
```bash
pub-watch start       # Start daemon
pub-watch stop        # Stop daemon
pub-watch restart     # Restart daemon
pub-watch status      # Show status
pub-watch logs [-f]   # View logs (optionally follow)
```

### Configuration
```bash
pub-watch config                        # Show all settings
pub-watch config set <key> <value>      # Update setting
```

Available settings:
- `check_interval` (seconds, default: 300)
- `release_metadata_timeout` (seconds, default: 180)
- `pub_availability_timeout` (seconds, default: 300)
- `enable_desktop_notif` (boolean, default: true)
- `pub_read_token` (string, default: "readonly54321")
- `worktree_base` (path, default: "/tmp/pub-watch-worktrees")

## How It Works

1. **Monitors** watch repo for commits from `sharmahemanta.212@gmail.com`
2. **Waits** for "chore: Update release metadata [skip ci]" commit (3 min timeout)
3. **Extracts** package names and versions from changed `pubspec.yaml` files
4. **Polls** `pub.tutero.dev` until new versions are available (5 min timeout)
5. **Clones** apply repo and creates worktree with branch name from trigger commit
6. **Updates** `pubspec.lock` with new versions and SHA256 hashes
7. **Validates** with `flutter pub get` and `fvm flutter build web --release`
8. **Creates** PR with original title and branch name

## File Locations

```
~/.cache/scripts/pub-watch/
├── repos.json        # Repository watch pairs
├── config.json       # Configuration
├── state.json        # Processing state
├── daemon.log        # Daemon logs
└── daemon.pid        # Process ID
```

## Testing

Test with historical data:
```bash
# Add test repositories
pub-watch add hemanta212/learning-library hemanta212/schools-app

# Run single check (no daemon)
~/dev/dotfiles/scripts/tutero/pub-watch/pub-watch-daemon --once
```

## Troubleshooting

### Daemon won't start
```bash
pub-watch logs        # Check for errors
pub-watch list        # Ensure repos are added
```

### No commits detected
- Verify repository access: `gh repo view <owner/repo>`
- Check author email in config
- Review logs: `pub-watch logs -f`

### Build failures
- Ensure `fvm` and `flutter` are installed
- Check apply repo has valid Flutter project
- Review build logs in daemon output

## Requirements

- `bash` 4.0+
- `jq` (JSON processing)
- `gh` (GitHub CLI, authenticated)
- `git` 2.30+
- `flutter` via fvm
- `fvm` (Flutter Version Management)
- `curl` (HTTP requests)
- `python3` (for YAML manipulation)

## Documentation

See detailed docs in `~/Coding/metarepo/frontend/`:
- [pub-watch-plan.md](../../../Coding/metarepo/frontend/pub-watch-plan.md) - Main plan & TODO
- [pub-watch-workflow.md](../../../Coding/metarepo/frontend/pub-watch-workflow.md) - Process flow
- [pub-watch-api.md](../../../Coding/metarepo/frontend/pub-watch-api.md) - API reference
- [pub-watch-config.md](../../../Coding/metarepo/frontend/pub-watch-config.md) - Configuration schemas
