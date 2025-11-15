#!/bin/bash

mkdir -p logs
MAX_SIZE=$((100 * 1024 * 1024)) # 100 MB

start_command() {
  $1 2>&1 | tee -a logs/output.log &
  cmd_pid=$!
}

cleanup() {
  echo "Stopping..."
  kill "$cmd_pid" 2>/dev/null
  wait "$cmd_pid" 2>/dev/null
  exit 0
}

# Trap all common exit signals
trap cleanup SIGINT SIGTERM SIGHUP EXIT

start_command "$1"

while true; do
  sleep 10

  # Rotate log if too big
  if [[ -f logs/output.log ]]; then
    # Use appropriate stat syntax for Linux vs macOS
    if stat -c%s logs/output.log >/dev/null 2>&1; then
      file_size=$(stat -c%s logs/output.log)
    else
      file_size=$(stat -f%z logs/output.log)
    fi
    
    if [[ $file_size -ge $MAX_SIZE ]]; then
      mv logs/output.log "logs/output_$(date +%Y%m%d_%H%M%S).log"
      touch logs/output.log
    fi
  fi

  # Delete logs older than 15 days
  find logs/ -type f -name "*.log" -mtime +15 -delete

  # Check if the command is still running
  if ! kill -0 "$cmd_pid" 2>/dev/null; then
    echo "Command crashed. Restarting in 5 seconds..."
    sleep 5
    start_command "$1"
  fi
done

