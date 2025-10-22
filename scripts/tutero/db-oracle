#!/usr/bin/env bash
set -euo pipefail

db=""
args=()
dirs=()
verbose=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -db)
    db="$2"
    shift 2
    ;;
  -v)
    verbose=true
    shift
    ;;
  --dirs)
    shift
    while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
      dirs+=("$1")
      shift
    done
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

if [ -z "$db" ]; then
  repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")")
  echo "Error: -db argument is required" >&2
  echo "Usage: $(basename "$0") -db <resources|learning|teaching> [-v] [--dirs <dir1> <dir2> ...] \"prompt\" [additional codex exec flags...]" >&2
  echo "Hint: The full pwd you're working on might give a clue, you're currently in '$repo_name'" >&2
  exit 1
fi

if [[ ! "$db" =~ ^(resources|learning|teaching)$ ]]; then
  echo "Error: -db must be one of: resources, learning, teaching" >&2
  exit 1
fi

if [ ${#args[@]} -eq 0 ]; then
  echo "Usage: $(basename "$0") -db <resources|learning|teaching> [-v] [--dirs <dir1> <dir2> ...] \"prompt\" [additional codex exec flags...]" >&2
  exit 1
fi

LOG_DIR="${HOME}/.cache/scripts/oracle-logs"
mkdir -p "$LOG_DIR"

timestamp="$(date "+%Y%m%dT%H%M%S")"
log_file="$LOG_DIR/${timestamp}-$$.log"
output_file="/tmp/db-oracle-output-$$.txt"

if [ ${#dirs[@]} -gt 0 ]; then
  dirs_text="Referenced Project/Repositories dir: ${dirs[*]}\n\n"
  if [ ${#args[@]} -gt 0 ]; then
    args[0]="${dirs_text}${args[0]}"
  fi
fi

set +e
if [ "$verbose" = true ]; then
  codex exec --skip-git-repo-check --config model_reasoning_effort="low" --cd "$HOME/Coding/metarepo" "${args[@]}" 2>&1 | tee "$log_file"
  exit_code=$?
else
  codex exec --skip-git-repo-check --config model_reasoning_effort="low" --cd "$HOME/Coding/metarepo" --output-last-message "$output_file" "${args[@]}" >"$log_file" 2>&1
  exit_code=$?
fi
set -e

if [ $exit_code -eq 0 ]; then
  if [ "$verbose" = false ]; then
    cat "$output_file"
  fi

  session_id="$(grep -oE 'session id: [[:alnum:]-]+' "$log_file" | cut -d' ' -f3)"
  if [ -n "$session_id" ]; then
    printf "\nThis was part of session '%s' provide --continue=%s if you wanna followup\n" "$session_id" "$session_id"
  fi
else
  cat "$log_file"
fi

exit "$exit_code"
