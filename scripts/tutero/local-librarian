#!/usr/bin/env bash
set -euo pipefail

# Capture the directory from which this script was invoked
INVOKE_DIR="$(pwd)"

verbose=false
show_help=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -v)
    verbose=true
    shift
    ;;
  --help | -h)
    show_help=true
    shift
    ;;
  *)
    echo "Error: Unexpected argument '$1'. Prompt must be provided via stdin." >&2
    exit 1
    ;;
  esac
done

if [ "$show_help" = true ]; then
  cat <<'EOF'
Usage: local-librarian [-v]

Arguments:
  -v                Verbose mode (show live output)
  --help, -h        Show this help message

Note: Prompt must be provided via stdin (pipe or redirect)
      Always specify the directory to search in your prompt!

Examples:
  # Pipe from echo
  echo "Search ~/Coding/mathgaps-org to find how spans and logs are uploaded to Grafana" | local-librarian
  
  # Multi-line heredoc (recommended)
  local-librarian <<EOF
  Search ~/Coding/myproject to find authentication logic.
  Look for middleware and JWT validation.
  EOF

EOF
  exit 0
fi

if [ -t 0 ]; then
  echo "Error: Prompt must be provided via stdin (pipe or redirect)" >&2
  echo "Usage: echo \"prompt\" | $(basename "$0") [-v]" >&2
  exit 1
fi

piped_input=$(cat)

LOG_DIR="${HOME}/.cache/scripts/local-librarian-logs"
mkdir -p "$LOG_DIR"

timestamp="$(date "+%Y%m%dT%H%M%S")"
log_file="$LOG_DIR/${timestamp}-$$.log"

# Prepare prompt with invocation directory context
final_prompt="Invoked Dir (CWD): ${INVOKE_DIR}"$'\n'
final_prompt="${final_prompt}(use as fallback if no dir specified to search)"$'\n\n'
final_prompt="${final_prompt}${piped_input}"

args=("$final_prompt")

# Change to home directory for read-only access to everything
cd "$HOME"

set +e
if [ "$verbose" = true ]; then
  opencode run --agent local-librarian "${args[@]}" 2>"$log_file"
  exit_code=$?
else
  opencode run --agent local-librarian "${args[@]}" 2>"$log_file"
  exit_code=$?
fi
set -e

if [ $exit_code -eq 0 ]; then
  if [ "$verbose" = false ]; then
    cat "$log_file"
  fi
else
  cat "$log_file"
fi

exit "$exit_code"
