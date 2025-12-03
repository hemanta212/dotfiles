#!/usr/bin/env bash
# Summary: Wraps codex exec sessions with background logging and resume help.
# Description:
# Executes Codex in the invoking directory while redirecting output into timestamped ~/.cache/scripts/autist logs.
# Spawns a background watcher that polls the log for the session ID so it can be replayed.
# Reads prompts from args or stdin and prefixes a strict oracle instruction before running the agent.
# Prints follow-up command templates and shows where the complete log lives on success or failure.

set -euo pipefail

# Capture the directory from which this script was invoked
INVOKE_DIR="$(pwd)"

# Parse flags
session_id=""
reasoning="high"
while [[ $# -gt 0 ]]; do
  case $1 in
  --help | -h)
    echo "Usage: $(basename "$0") [-s|--session SESSION_ID] \"prompt\"" >&2
    echo "   or: echo \"prompt\" | $(basename "$0") [-s|--session SESSION_ID]" >&2
    echo "   or: $(basename "$0") [-s|--session SESSION_ID] <<EOF" >&2
    echo "       prompt text here" >&2
    echo "       EOF" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  -s, --session SESSION_ID    Resume an existing codex session" >&2
    echo "  -h, --help                  Show this help message" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  autist \"analyze this codebase\"" >&2
    echo "  echo \"refactor the auth module\" | autist" >&2
    echo "  autist -s abc123 <<EOF" >&2
    echo "  continue from where we left off" >&2
    echo "  EOF" >&2
    exit 0
    ;;
  -s | --session)
    session_id="$2"
    shift 2
    ;;
  -r)
    reasoning="$2"
    if [[ ! "$reasoning" =~ ^(low|medium|high)$ ]]; then
      echo "Error: -r must be one of: low, medium, high" >&2
      exit 1
    fi
    shift 2
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
    echo "Usage: $(basename "$0") [-s|--session SESSION_ID] \"prompt\"" >&2
    echo "   or: echo \"prompt\" | $(basename "$0") [-s|--session SESSION_ID]" >&2
    echo "   or: $(basename "$0") [-s|--session SESSION_ID] <<EOF" >&2
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

# Prepend system instruction to establish oracle role
oracle_instruction="You are a read-only advisory oracle consulted for complex analysis, planning, and reviews.
Do not perform implementation work yourself - focus strictly on researching, analyzing, and providing expert guidance.
Review the situation thoroughly and respond with actionable advice that adheres to the query's requirements.

USER QUERY:
"
prompt="${oracle_instruction}${prompt}"

# Setup logging
LOG_DIR="${HOME}/.cache/scripts/autist"
mkdir -p "$LOG_DIR"

timestamp="$(date "+%Y%m%dT%H%M%S")"
log_file="$LOG_DIR/${timestamp}-$$.log"
output_file="/tmp/autist-output-$$.txt"
session_marker="/tmp/autist-session-marker-$$.txt"

# Start background log watcher to extract session ID as soon as available
# This runs concurrently while codex is executing (non-blocking read)
(
  # Wait for log file to be created
  timeout=50
  while [ ! -f "$log_file" ] && [ $timeout -gt 0 ]; do
    sleep 0.1
    timeout=$((timeout - 1))
  done

  if [ -f "$log_file" ]; then
    # Poll the log file every 5 seconds to extract session ID
    printf "🔍 Waiting for session ID" >&2
    while true; do
      extracted_id="$(grep -oE 'session id: [[:alnum:]-]+' "$log_file" 2>/dev/null | head -n1 | cut -d' ' -f3)"
      if [ -n "$extracted_id" ]; then
        echo "$extracted_id" >"$session_marker"
        printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
        printf "⏱️  Session started: %s\n" "$extracted_id" >&2
        printf "💡 If timeout occurs, continue with:\n" >&2
        printf "   autist -s %s <<'EOF'\n" "$extracted_id" >&2
        printf "   continue\n" >&2
        printf "   EOF\n" >&2
        printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" >&2
        break
      else
        # Session ID not found yet, print a dot and wait
        printf "." >&2
        sleep 5
      fi
    done
  fi
) &
watcher_pid=$!

# Execute codex with the detected directory
set +e
if [ -n "$session_id" ]; then
  # Resume existing session
  codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    --skip-git-repo-check \
    --config model_reasoning_effort="$reasoning" \
    --cd "$INVOKE_DIR" \
    --output-last-message "$output_file" \
    resume "$session_id" \
    "$prompt" \
    >"$log_file" 2>&1
  exit_code=$?
else
  # Start new session
  codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    --skip-git-repo-check \
    --config model_reasoning_effort="$reasoning" \
    --cd "$INVOKE_DIR" \
    --output-last-message "$output_file" \
    "$prompt" \
    >"$log_file" 2>&1
  exit_code=$?
fi
set -e

# Kill the background watcher (if still running)
kill "$watcher_pid" 2>/dev/null || true
wait "$watcher_pid" 2>/dev/null || true

# Handle output
if [ $exit_code -eq 0 ]; then
  cat "$output_file"

  # Display session ID again for follow-ups (read from marker file or extract from log)
  extracted_session_id=""
  if [ -f "$session_marker" ]; then
    extracted_session_id="$(cat "$session_marker")"
  else
    extracted_session_id="$(grep -oE 'session id: [[:alnum:]-]+' "$log_file" | cut -d' ' -f3 || true)"
  fi

  if [ -n "$extracted_session_id" ]; then
    printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "✅ Session completed: %s\n" "$extracted_session_id"
    printf "💬 To follow up, use: autist -s %s <<'EOF'\n" "$extracted_session_id"
    printf "   [your follow-up prompt]\n"
    printf "   EOF\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  fi

  # Show where logs are stored
  printf "[debug] Logs saved to: %s\n" "$log_file" >&2
else
  # On error, show the full logs
  cat "$log_file"
  printf "\n[debug] Logs saved to: %s\n" "$log_file" >&2
fi

# Cleanup temp files
rm -f "$output_file" "$session_marker"

exit "$exit_code"
