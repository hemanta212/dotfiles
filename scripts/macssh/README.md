# SSH Reverse Tunnel (Manual Control + Auto-Retry)

## Initial Setup (One-Time)

```bash
# 1. Copy SSH config to disable password auth
sudo cp ~/dev/dotfiles/scripts/macssh/sshd_config_custom /etc/ssh/sshd_config.d/99-disable-password-auth.conf

# 2. Enable SSH (System Settings > General > Sharing > Remote Login)
# OR: sudo launchctl start com.openssh.sshd

# 3. Restart SSH to apply config
sudo launchctl kickstart -k system/com.openssh.sshd

# 4. Verify password auth is disabled
sudo sshd -T | grep passwordauthentication  # Should show: passwordauthentication no

# 5. Symlink to PATH
ln -sf ~/dev/dotfiles/scripts/macssh/ssh-tunnel ~/.local/bin/ssh-tunnel
```

## Usage

```bash
ssh-tunnel start    # Start tunnel (with auto-reconnect on disruptions)
ssh-tunnel stop     # Stop completely
ssh-tunnel status   # Check status
ssh-tunnel logs     # View last 30 log lines
ssh-tunnel logs -f  # Live tail
```

## Connect from Anywhere

```bash
ssh -p 6969 mac@vps.osac.org.np
```

## Features

- Manual start/stop (no auto-start on boot)
- Auto-reconnect on network disruptions
- Exponential backoff (10s → 20s → 40s → 80s → max 5min)
- Network connectivity checks before retry
- Resets retry counter after 5min stable

## Files

- `ssh-tunnel` - Main script (symlink to ~/.local/bin/)
- `sshd_config_custom` - SSH server config (disables password auth)
- Logs: `~/.ssh-tunnel.log`, `~/.ssh-tunnel-error.log`
