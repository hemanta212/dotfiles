#!/bin/bash
# Summary: Adds Telegram IP ranges via the utun4 WireGuard interface.
# Description:
# Verifies the utun4 interface exists before touching routes.
# Adds static routes for known Telegram CIDRs through utun4.
# Sleeps indefinitely afterward so the interface stays bound until you stop it.
# Exits early if the interface is down so you can rerun the script later.


if ! wg show utun4 >/dev/null; then
  sleep 10
  exit 1
fi

# Telegram IP ranges
while read -r line; do
  route add "$line" -interface utun4
done <<EOF
95.161.64.0/20
149.154.160.0/22
149.154.164.0/22
91.108.4.0/22
91.108.56.0/22
91.108.8.0/22
149.154.160.0/23
149.154.162.0/23
149.154.164.0/23
149.154.166.0/23
EOF

# macOS equivalent of chpst -b wireguard pause - just sleep indefinitely
exec sleep infinity
