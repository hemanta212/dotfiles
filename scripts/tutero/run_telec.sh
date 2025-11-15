#!/bin/bash

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
