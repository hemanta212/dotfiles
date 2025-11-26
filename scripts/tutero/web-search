#!/usr/bin/env bash
# Summary: Wrapper for opencode web-search agent with retry on failure.

set -euo pipefail

# Prevent recursive invocation - opencode's web-search agent may call this script
if [ "${_WEB_SEARCH_RUNNING:-}" = "1" ]; then
  echo "Error: web-search cannot be called recursively" >&2
  exit 1
fi
export _WEB_SEARCH_RUNNING=1

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: web-search "prompt"
   or: echo "prompt" | web-search

Examples:
  web-search "latest news on AI"
  echo "what is the weather in NYC" | web-search
EOF
  exit 0
fi

# Read prompt from arguments first, fall back to stdin
if [ $# -gt 0 ]; then
  prompt="$*"
elif [ ! -t 0 ]; then
  prompt="$(cat)"
  if [ -z "$prompt" ]; then
    echo "Error: No prompt provided via stdin" >&2
    exit 1
  fi
else
  echo "Usage: $(basename "$0") \"prompt\"" >&2
  echo "   or: echo \"prompt\" | $(basename "$0")" >&2
  exit 1
fi

LOG_DIR="${HOME}/.cache/scripts/web-search"
mkdir -p "$LOG_DIR"
timestamp="$(date "+%Y%m%dT%H%M%S")"
log_file="$LOG_DIR/${timestamp}-$$.log"

max_retries=2
retry_count=0

while [ $retry_count -lt $max_retries ]; do
  set +e
  opencode run --agent web-search "$prompt" 2>&1 | tee "$log_file"
  exit_code=${PIPESTATUS[0]}
  set -e
  
  if [ $exit_code -eq 0 ]; then
    exit 0
  fi
  
  retry_count=$((retry_count + 1))
  if [ $retry_count -lt $max_retries ]; then
    echo "[exit code $exit_code, retry $retry_count/$max_retries]" >&2
    sleep 0.5
  fi
done

exit $exit_code
