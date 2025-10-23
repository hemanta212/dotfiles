#!/usr/bin/env bash
set -euo pipefail

INVOCATION_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run"

cd "$INVOCATION_DIR"
if [ ! -f "$RUN_SCRIPT" ]; then
  echo "Error: expected executable at ./run but file is missing." >&2
  exit 1
fi

if [ ! -x "$RUN_SCRIPT" ]; then
  echo "Error: ./run exists but is not executable. Run 'chmod +x ./run'." >&2
  exit 1
fi

sanitize_prefix() {
  local raw="$1"
  # Replace unsafe characters with underscores to keep logfile path predictable.
  printf '%s' "$raw" | tr '[:space:]/' '__' | tr -cd '[:alnum:]._-'
}

choose_log_path() {
  local prefix="${DEBUG_PREFIX:-}"
  local base="/tmp/resources.run.log"
  if [ -n "$prefix" ]; then
    local clean_prefix
    clean_prefix="$(sanitize_prefix "$prefix")"
    if [ -n "$clean_prefix" ]; then
      base="/tmp/resources.${clean_prefix}.run.log"
    fi
  fi

  local candidate="$base"
  local idx=1
  while [ -e "$candidate" ]; do
    candidate="${base}.${idx}"
    idx=$((idx + 1))
  done

  printf '%s\n' "$candidate"
}

LOG_PATH="$(choose_log_path)"
: >"$LOG_PATH"

TAIL_PID=""
stop_tail() {
  if [ -n "$TAIL_PID" ]; then
    if kill -0 "$TAIL_PID" 2>/dev/null; then
      kill "$TAIL_PID" 2>/dev/null || true
    fi
    wait "$TAIL_PID" 2>/dev/null || true
    TAIL_PID=""
  fi
}

tail -n +1 -f "$LOG_PATH" &
TAIL_PID=$!
trap stop_tail EXIT INT TERM

nohup "$RUN_SCRIPT" >"$LOG_PATH" 2>&1 </dev/null &
SERVER_PID=$!

# Short delay to surface immediate failures before the loop.
sleep 0.5

TIMEOUT_SECONDS="${RUN_AUTO_TIMEOUT:-60}"
SLEEP_INTERVAL=1
elapsed=0

wait_for_running() {
  while [ "$elapsed" -lt "$TIMEOUT_SECONDS" ]; do
    if grep -q "RUNNING" "$LOG_PATH"; then
      return 0
    fi

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      stop_tail
      echo "Server process exited before reaching RUNNING state." >&2
      tail -50 "$LOG_PATH" >&2
      return 1
    fi

    sleep "$SLEEP_INTERVAL"
    elapsed=$((elapsed + SLEEP_INTERVAL))
  done

  stop_tail
  echo "Timed out (${TIMEOUT_SECONDS}s) waiting for RUNNING log line." >&2
  tail -50 "$LOG_PATH" >&2
  return 1
}

if ! wait_for_running; then
  exit 1
fi

printf '\nFollow Logs with tail -f : %s [Note: Killing is unnecessary, re-run to kill + start again]\n' "$LOG_PATH"

stop_tail
