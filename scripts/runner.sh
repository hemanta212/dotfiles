#!/bin/bash

mkdir -p logs
MAX_SIZE=$((100 * 1024 * 1024)) # 100 MB

cmd_pid=""
tail_pid=""
log_file=""

# Generate log filename from command (e.g., ./scheduler.sh -> scheduler)
get_log_name() {
  local cmd="$1"
  local name=$(basename "$cmd" .sh)
  name=$(basename "$name" .py)
  echo "logs/${name}.log"
}

start_command() {
  # Kill old tail if exists (on restart)
  if [[ -n "$tail_pid" ]] && kill -0 "$tail_pid" 2>/dev/null; then
    kill "$tail_pid" 2>/dev/null
  fi
  "$@" >>"$log_file" 2>&1 &
  cmd_pid=$!
  # Tail log to stdout for live viewing (-n0 = only new lines)
  tail -n0 -f "$log_file" &
  tail_pid=$!
  echo ":: Started command (PID: $cmd_pid)"
}

cleanup() {
  echo ""
  echo ":: Stopping (received signal)..."
  # Kill tail first
  if [[ -n "$tail_pid" ]] && kill -0 "$tail_pid" 2>/dev/null; then
    kill "$tail_pid" 2>/dev/null
  fi
  # Then kill main command
  if [[ -n "$cmd_pid" ]] && kill -0 "$cmd_pid" 2>/dev/null; then
    kill -TERM "$cmd_pid" 2>/dev/null
    wait "$cmd_pid" 2>/dev/null
  fi
  echo ":: Stopped at $(date)"
  exit 0
}

trap cleanup SIGINT SIGTERM SIGHUP

if [[ -z "$1" ]]; then
  echo "Usage: ./runner.sh <command>"
  exit 1
fi

log_file=$(get_log_name "$1")
touch "$log_file"

echo ":: Runner started at $(date)"
echo ":: Command: $*"
echo ":: Log: $log_file"

start_command "$@"

while true; do
  # Signal-interruptible sleep using background sleep + wait
  sleep 5 &
  wait $! 2>/dev/null

  # Rotate log if too big
  if [[ -f "$log_file" ]]; then
    size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null)
    if [[ "$size" -ge $MAX_SIZE ]]; then
      mv "$log_file" "${log_file%.log}_$(date +%Y%m%d_%H%M%S).log"
      touch "$log_file"
      echo ":: Log rotated"
    fi
  fi

  # Delete logs older than 15 days
  find logs/ -type f -name "*.log" -mtime +15 -delete 2>/dev/null

  # Check if the command is still running
  if ! kill -0 "$cmd_pid" 2>/dev/null; then
    echo ":: Command exited. Restarting in 5 seconds..."
    sleep 5 &
    wait $! 2>/dev/null
    start_command "$@"
  fi
done
