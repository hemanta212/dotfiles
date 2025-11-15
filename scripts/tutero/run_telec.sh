#!/bin/bash
# Summary: Runs the telec function every five seconds to keep the telemetry agent warm.
# Description:
# Loops indefinitely, invoking zsh -ic telec every five seconds with timestamps for traceability.
# Prints headers before each run so you can see when it last executed.
# Relies on the telec function defined in ~/.config/zsh/zsh/functionrc.
# Stays alive until interrupted so other automation keeps the remote session warm.


# Script to run 'telec' function every 5 seconds
# The function is defined in ~/.config/zsh/zsh/functionrc

echo "Starting telec runner (every 5 seconds)..."
echo "Press Ctrl+C to stop"
echo ""

while true; do
    echo "=== Running telec at $(date '+%Y-%m-%d %H:%M:%S') ==="
    zsh -ic 'telec'
    echo ""
    sleep 5
done
