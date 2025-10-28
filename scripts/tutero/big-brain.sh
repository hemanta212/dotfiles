#!/usr/bin/env bash
set -euo pipefail

# Capture the directory from which this script was invoked
INVOKE_DIR="$(pwd)"

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
  --help | -h)
    echo "Usage: $(basename "$0") \"prompt\"" >&2
    echo "   or: echo \"prompt\" | $(basename "$0")" >&2
    echo "   or: $(basename "$0") <<EOF" >&2
    echo "       prompt text here" >&2
    echo "       EOF" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  big-brain \"How should we refactor the auth system?\"" >&2
    echo "  echo \"What's the best approach for real-time notifications?\" | big-brain" >&2
    echo "  big-brain <<EOF" >&2
    echo "  Should we use a monorepo or separate repos?" >&2
    echo "  EOF" >&2
    exit 0
    ;;
  *)
    break
    ;;
  esac
done

# Read prompt from stdin if available, otherwise use arguments
if [ -t 0 ]; then
  # stdin is a terminal (no pipe/heredoc), use arguments
  if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") \"prompt\"" >&2
    echo "   or: echo \"prompt\" | $(basename "$0")" >&2
    echo "   or: $(basename "$0") <<EOF" >&2
    echo "       prompt text here" >&2
    echo "       EOF" >&2
    echo "" >&2
    echo "Use --help for more information" >&2
    exit 1
  fi
  prompt="$*"
else
  # stdin has data (pipe or heredoc), read it
  prompt="$(cat)"
  if [ -z "$prompt" ]; then
    echo "Error: No prompt provided" >&2
    exit 1
  fi
fi

# Setup logging
LOG_DIR="${HOME}/.cache/scripts/big-brain"
mkdir -p "$LOG_DIR"

timestamp="$(date "+%Y%m%dT%H%M%S")"
log_file="$LOG_DIR/${timestamp}-$$.log"

# Execute opencode from the invoked directory
cd "$INVOKE_DIR"

set +e
opencode run --agent big-brain "$prompt" 2>&1 | tee "$log_file"
exit_code=$?
set -e

if [ $exit_code -ne 0 ]; then
  printf "\n[debug] Logs saved to: %s\n" "$log_file" >&2
fi

exit "$exit_code"
