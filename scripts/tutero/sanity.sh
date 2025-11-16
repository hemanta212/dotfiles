#!/usr/bin/env bash
# ^ Tell the system to use bash to execute this script

# Exit on error (-e), error on undefined variables (-u), fail pipelines on first error (-o pipefail)
# This makes the script safer by stopping execution when things go wrong
set -euo pipefail

# =============================================================================
# sanity.sh - Log processing and pretty printing utility
# =============================================================================
# Extracts JSON logs, formats stacktraces, and filters output
# Usage: some_command | ./sanity.sh
#        ./sanity.sh < logfile.log
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration Variables
# -----------------------------------------------------------------------------
# FX_LOGS: Control whether to show FX framework logs ([Fx], [F0-9x])
# Default is "false" (hides FX logs). Set to "true" to show them.
# The ${VAR:-default} syntax means: use $FX_LOGS if set, otherwise use "false"
FX_LOGS="${FX_LOGS:-false}"
MULTILINE_STRING_MIN_LINES="${MULTILINE_STRING_MIN_LINES:-4}"
MULTILINE_ENTRIES_RESULT=""
CURRENT_MULTILINE_ENTRIES=""
OUTPUT_MODE="${SANITY_OUTPUT_MODE:-pretty}"
LOG_COUNTER=0

# -----------------------------------------------------------------------------
# JQ Program for JSON Processing
# -----------------------------------------------------------------------------
# This is a jq program stored as a bash variable (heredoc syntax)
# It processes each line: tries to parse as JSON, extracts stacktraces
# Note: FX logs filtering is done in bash loop, not here in JQ
#
# The <<'JQ' syntax is a "heredoc" - it reads multi-line text until it sees "JQ"
# The 'JQ' quotes prevent variable expansion inside the heredoc
# The "|| true" prevents the script from exiting if read returns non-zero
read -r -d '' JQ_PROGRAM <<'JQ' || true
. as $raw
| try fromjson catch $raw
| if (type == "object" and has("stacktrace")) then
    (del(.stacktrace) | to_entries[] | "\(.key): \(.value)"),
    "stacktrace:",
    (.stacktrace | split("\n") | map("  " + .) | .[])
  else
    .
  end
JQ

read -r -d '' NESTED_JSON_TRANSFORM <<'JQ' || true
def strip_ws:
  sub("^[[:space:]]+";"")
  | sub("[[:space:]]+$";"");

def decode_nested:
  if type == "string" then
    ( . as $original
      | (.|strip_ws) as $trimmed
      | if (( $trimmed | startswith("{") ) or ( $trimmed | startswith("[") ))
        and (( $trimmed | endswith("}") ) or ( $trimmed | endswith("]") ))
        then (try ($trimmed | fromjson | decode_nested) catch $original)
        else $original
        end)
  elif type == "array" then
    map(decode_nested)
  elif type == "object" then
    with_entries(.value |= decode_nested)
  else
    .
  end;

decode_nested
JQ

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------
# Print an info message with :: prefix
log_info() {
  # $* expands all arguments as a single string
  printf ':: %s\n' "$*"
}

# Print an error message to stderr (>&2 redirects to stderr)
log_error() {
  printf ':: %s\n' "$*" >&2
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
is_json() {
  local input=$1
  if printf '%s' "$input" | jq empty >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

looks_like_json_start() {
  local trimmed
  trimmed=$(printf '%s' "$1" | sed -e 's/^[[:space:]]*//')
  if [[ -z "$trimmed" ]]; then
    return 1
  fi

  local first_char=${trimmed:0:1}
  if [[ "$first_char" == "{" ]]; then
    return 0
  fi

  if [[ "$first_char" == "[" ]]; then
    local second_char=${trimmed:1:1}
    if [[ -z "$second_char" ]]; then
      return 0
    fi
    case "$second_char" in
    $'\n'|$'\t'|$'\r'|' '|'"'|'{'|'['|']'|0|1|2|3|4|5|6|7|8|9|-)
      return 0
      ;;
    esac
  fi

  return 1
}

normalize_nested_json() {
  jq -c "$NESTED_JSON_TRANSFORM" 2>/dev/null || cat
}

add_multiline_entry() {
  local list=$1
  local path=$2
  local value=$3
  local encoded
  encoded=$(jq -Rn --arg path "$path" --arg value "$value" '{path:$path, value:$value}' | base64)
  if [[ -n "$list" ]]; then
    printf '%s\n%s' "$list" "$encoded"
  else
    printf '%s' "$encoded"
  fi
}

render_mixed_block() {
  local value=${1//$'\r'/}
  local line
  local json_buffer=""
  local capturing_json=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ((capturing_json == 1)); then
      json_buffer+=$'\n'"$line"
      if is_json "$json_buffer"; then
        printf '%s\n' "$json_buffer" | jq --color-output --indent 2 .
        json_buffer=""
        capturing_json=0
      fi
      continue
    fi

    if looks_like_json_start "$line"; then
      json_buffer="$line"
      capturing_json=1
      if is_json "$json_buffer"; then
        printf '%s\n' "$json_buffer" | jq --color-output --indent 2 .
        json_buffer=""
        capturing_json=0
      fi
      continue
    fi

    printf '%s\n' "$line"
  done <<<"$value"

  if ((capturing_json == 1)) && [[ -n "$json_buffer" ]]; then
    if is_json "$json_buffer"; then
      printf '%s\n' "$json_buffer" | jq --color-output --indent 2 .
    else
      printf '%s\n' "$json_buffer"
    fi
  fi
}

print_multiline_entries() {
  local entries=${1:-$CURRENT_MULTILINE_ENTRIES}
  if [[ -z "${entries// }" ]]; then
    return
  fi

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local decoded path value
    decoded=$(printf '%s' "$entry" | base64 --decode 2>/dev/null) || continue
    path=$(printf '%s' "$decoded" | jq -r '.path' 2>/dev/null) || continue
    value=$(printf '%s' "$decoded" | jq -r '.value' 2>/dev/null) || continue
    path=${path#/}
    printf '\033[0;35m%s:\033[0m\n' "$path"
    render_mixed_block "$value"
    printf '\n'
  done <<<"$entries"
}

emit_log_record() {
  local json_payload=$1
  local entries=${2:-$CURRENT_MULTILINE_ENTRIES}
  local summary_json
  summary_json=$(printf '%s' "$json_payload" | jq -c '{time:(.time // ""), severity:(.severity // .level // ""), message:(.message // ""), caller:(.caller // "")}' 2>/dev/null || printf '{"time":"","severity":"","message":"","caller":""}')
  printf '%s\n' "$(printf '%s\n' "$json_payload" | jq -c --arg idx "$LOG_COUNTER" --argjson summary "$summary_json" '{type:"log", index:($idx|tonumber), summary:$summary, json:.}')"

  if [[ -n "${entries// }" ]]; then
    while IFS= read -r entry || [[ -n "$entry" ]]; do
      [[ -z "$entry" ]] && continue
      local decoded path value
      decoded=$(printf '%s' "$entry" | base64 --decode 2>/dev/null) || continue
      path=$(printf '%s' "$decoded" | jq -r '.path' 2>/dev/null) || continue
      value=$(printf '%s' "$decoded" | jq -r '.value' 2>/dev/null) || continue
      jq -n -c --arg idx "$LOG_COUNTER" --arg path "$path" --arg value "$value" '{type:"block", index:($idx|tonumber), path:$path, value:$value}'
    done <<<"$entries"
  fi

  ((++LOG_COUNTER))
}

emit_plain_record() {
  local text=$1
  jq -n -c --arg idx "$LOG_COUNTER" --arg text "$text" '{type:"text", index:($idx|tonumber), text:$text}'
  ((++LOG_COUNTER))
}

process_multiline_fields() {
  local json=$1
  local __outvar=$2
  local min_lines=${MULTILINE_STRING_MIN_LINES:-4}
  local result cleaned entries

  result=$(printf '%s' "$json" | jq -c --argjson min "$min_lines" '
    def target_paths:
      [paths(strings) as $p
       | (getpath($p)) as $v
       | select(($v | split("\n") | length) >= $min)
       | $p];
    def entries($paths):
      [$paths[]? as $p
       | {path: ([""] + $p | join("/")), value: (getpath($p))}];
    (target_paths) as $paths
    | {clean: delpaths($paths), entries: entries($paths)}
  ' 2>/dev/null) || {
    MULTILINE_ENTRIES_RESULT=""
    printf -v "$__outvar" '%s' "$json"
    return
  }

  cleaned=$(printf '%s' "$result" | jq -c '.clean' 2>/dev/null)
  entries=$(printf '%s' "$result" | jq -r '.entries[]? | @base64' 2>/dev/null)
  MULTILINE_ENTRIES_RESULT="$entries"

  if [[ -z "$cleaned" || "$cleaned" == "null" ]]; then
    printf -v "$__outvar" '%s' "$json"
  else
    printf -v "$__outvar" '%s' "$cleaned"
  fi
}

# -----------------------------------------------------------------------------
# Format a Single Log Line
# -----------------------------------------------------------------------------
# This function does the heavy lifting:
# - Detects if the line is JSON
# - Extracts and color-codes stacktraces from error objects
# - Filters based on DEBUG_PREFIX if set
# - Pretty prints JSON with indentation
format_service_line() {
  # "local" makes the variable only exist inside this function
  local line=$1

  # -------------------------------------------------------------------------
  # Step 1: Check if line is valid JSON
  # -------------------------------------------------------------------------
  # We pipe the line to "jq empty" which validates JSON without output
  # 2>/dev/null hides error messages, so only the exit code matters
  # If jq succeeds (exit code 0), the line is valid JSON
  if is_json "$line"; then
    line=$(printf '%s' "$line" | normalize_nested_json)
    MULTILINE_ENTRIES_RESULT=""
    process_multiline_fields "$line" line
    local multiline_entries="$MULTILINE_ENTRIES_RESULT"
    
    # -----------------------------------------------------------------------
    # Step 2: Apply DEBUG_PREFIX filtering (if DEBUG_PREFIX env var is set)
    # -----------------------------------------------------------------------
    # [[ -n "${VAR:-}" ]] checks if variable is non-empty
    # The :- prevents errors if DEBUG_PREFIX doesn't exist
    if [[ -n "${DEBUG_PREFIX:-}" ]]; then
      local severity prefix should_show
      
      # Extract severity/level from JSON (e.g., "ERROR", "INFO")
      # The // operator in jq means "or" - tries .severity, then .level, then ""
      # -r flag makes jq output raw strings (no quotes)
      severity=$(printf '%s' "$line" | jq -r '.severity // .level // ""' 2>/dev/null)
      
      # Extract prefix field from JSON
      prefix=$(printf '%s' "$line" | jq -r '.prefix // ""' 2>/dev/null)

      # Flag to track if we should display this log (0 = no, 1 = yes)
      should_show=0
      
      # Always show warnings and errors (important logs shouldn't be filtered)
      # =~ does regex matching in bash
      if [[ "$severity" =~ ^(warn|warning|error|fatal|panic|dpanic)$ ]]; then
        should_show=1
      # Show logs where prefix matches DEBUG_PREFIX
      elif [[ "$prefix" == "$DEBUG_PREFIX" ]]; then
        should_show=1
      fi

      # If we decided not to show this log, return early (skip processing)
      # (( )) is bash arithmetic context - treats 0 as false, non-zero as true
      if ((should_show == 0)); then
        return
      fi
    fi

    # -----------------------------------------------------------------------
    # Step 3: Check for error.stacktrace and error.messages
    # -----------------------------------------------------------------------
    local has_error_stack has_error_messages
    # Check if there's an .error.stacktrace field
    has_error_stack=$(printf '%s' "$line" | jq -r 'if type == "object" and has("error") and (.error | type == "object" and has("stacktrace")) then "yes" else "no" end' 2>/dev/null || echo "no")
    # Check if there's an .error.messages field
    has_error_messages=$(printf '%s' "$line" | jq -r 'if type == "object" and has("error") and (.error | type == "object" and has("messages")) then "yes" else "no" end' 2>/dev/null || echo "no")

    # -----------------------------------------------------------------------
    # Step 4: Extract and format stacktrace and/or messages
    # -----------------------------------------------------------------------
    if [[ "$has_error_stack" == "yes" ]] || [[ "$has_error_messages" == "yes" ]]; then
      # We have special error fields to extract
      local cleaned_json="$line"
      local entries_data="$multiline_entries"
      local formatted_stack=""
      local stacktrace=""
      local formatted_messages=""
      
      # Remove stacktrace if it exists
      if [[ "$has_error_stack" == "yes" ]]; then
        cleaned_json=$(printf '%s' "$cleaned_json" | jq 'del(.error.stacktrace)')
      fi
      
      # Remove messages if they exist
      if [[ "$has_error_messages" == "yes" ]]; then
        cleaned_json=$(printf '%s' "$cleaned_json" | jq 'del(.error.messages)')
      fi
      
      
      # Now print stacktrace if it exists
      if [[ "$has_error_stack" == "yes" ]]; then
        stacktrace=$(printf '%s' "$line" | jq -r '.error.stacktrace')
        entries_data=$(add_multiline_entry "$entries_data" "error.stacktrace" "$stacktrace")
        formatted_stack=$(printf '%s' "$stacktrace" | awk '
          /^Oops:/ || /^Thrown:/ {
            print "\033[1;31m" $0 "\033[0m"
            next
          }
          /^[[:space:]]*--- at/ {
            print "\033[0;36m" $0 "\033[0m"
            next
          }
          {
            print $0
          }
        ')
      fi
      
      # Now print messages if they exist
      if [[ "$has_error_messages" == "yes" ]]; then
        local messages messages_type
        
        # Get the type of messages (string or array)
        messages_type=$(printf '%s' "$line" | jq -r '.error.messages | type' 2>/dev/null || echo "null")
        
        if [[ "$messages_type" == "string" ]]; then
          messages=$(printf '%s' "$line" | jq -r '.error.messages')
          formatted_messages=$(printf '%s' "$messages" | sed 's/^/  /')
        elif [[ "$messages_type" == "array" ]]; then
          formatted_messages=$(printf '%s' "$line" | jq -r '.error.messages | map("  " + .) | .[]')
        else
          formatted_messages="  (unable to format messages)"
        fi

        entries_data=$(add_multiline_entry "$entries_data" "error.messages" "$formatted_messages")
      fi

      CURRENT_MULTILINE_ENTRIES="$entries_data"

      if [[ "$OUTPUT_MODE" == "blocks" ]]; then
        emit_log_record "$cleaned_json" "$entries_data"
      else
        printf '%s\n' "$cleaned_json" | jq --indent 2 .
        print_multiline_entries "$entries_data"
        if [[ "$has_error_stack" == "yes" ]]; then
          printf '\033[1;33mFormatted Stacktrace:\033[0m\n'
          printf '%s\n' "$formatted_stack"
        fi
        if [[ "$has_error_messages" == "yes" ]]; then
          printf '\033[1;33mError Messages:\033[0m\n'
          printf '%s\n' "$formatted_messages"
        fi
      fi
    else
      # ---------------------------------------------------------------------
      # Step 5: No special error fields, just pretty print the JSON
      # ---------------------------------------------------------------------
      CURRENT_MULTILINE_ENTRIES="$multiline_entries"
      if [[ "$OUTPUT_MODE" == "blocks" ]]; then
        emit_log_record "$line" "$CURRENT_MULTILINE_ENTRIES"
      else
        printf '%s\n' "$line" | jq --indent 2 .
        print_multiline_entries "$CURRENT_MULTILINE_ENTRIES"
      fi
    fi
  else
    # -----------------------------------------------------------------------
    # Not JSON - print the line as-is without processing
    # -----------------------------------------------------------------------
    if [[ "$OUTPUT_MODE" == "blocks" ]]; then
      emit_plain_record "$line"
    else
      printf '%s\n' "$line"
    fi
  fi
}

# -----------------------------------------------------------------------------
# Process Streaming Logs from stdin (Main Processing Mode)
# -----------------------------------------------------------------------------
# Reads logs line by line, filters FX logs based on FX_LOGS flag,
# then passes each line to format_service_line for JSON processing
process_logs() {
  local line buffer=""
  local buffer_active=0
  local buffer_lines=0
  local max_buffer_lines=${MAX_MULTILINE_JSON_LINES:-400}
  
  # Read from stdin line by line
  # IFS= prevents trimming of leading/trailing whitespace
  # -r prevents backslash escaping
  # || [[ -n "$line" ]] ensures we process the last line even if it has no newline
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}

    if ((buffer_active == 1)); then
      buffer+=$'\n'"$line"
      ((buffer_lines++))

      if is_json "$buffer"; then
        format_service_line "$buffer"
        buffer=""
        buffer_active=0
        buffer_lines=0
        continue
      fi

      if ((buffer_lines >= max_buffer_lines)); then
        if [[ "$OUTPUT_MODE" == "blocks" ]]; then
          emit_plain_record "$buffer"
        else
          printf '%s\n' "$buffer"
        fi
        buffer=""
        buffer_active=0
        buffer_lines=0
      fi

      continue
    fi
    
    # Filter FX framework logs if FX_LOGS is false (the default)
    # =~ does regex pattern matching
    # ^\[F[0-9x]\] matches lines starting with [Fx], [F0], [F1], etc.
    if [[ "$FX_LOGS" == "false" ]] && [[ $line =~ ^\[F[0-9x]\] ]]; then
      # "continue" skips to the next iteration of the loop
      continue
    fi

    if is_json "$line"; then
      format_service_line "$line"
      continue
    fi

    if looks_like_json_start "$line"; then
      buffer="$line"
      buffer_active=1
      buffer_lines=1
      continue
    fi

    # Process this log line (format JSON, extract stacktraces, etc.)
    if [[ "$OUTPUT_MODE" == "blocks" ]]; then
      emit_plain_record "$line"
    else
      printf '%s\n' "$line"
    fi
  done

  if ((buffer_active == 1)); then
    if is_json "$buffer"; then
      format_service_line "$buffer"
    else
      if [[ "$OUTPUT_MODE" == "blocks" ]]; then
        emit_plain_record "$buffer"
      else
        printf '%s\n' "$buffer"
      fi
    fi
  fi
}

# -----------------------------------------------------------------------------
# Alternative Processing Mode: Pure JQ (Faster but Less Formatting)
# -----------------------------------------------------------------------------
# This is more efficient for large log streams but doesn't do color coding
# Uses the JQ_PROGRAM we defined earlier
process_logs_with_jq() {
  # -R reads raw input (not as JSON), -r outputs raw strings
  # 2>/dev/null hides jq errors
  # || cat ensures if jq fails, we still pass through the input
  jq -Rr "$JQ_PROGRAM" 2>/dev/null || cat
}

# =============================================================================
# Main Entry Point
# =============================================================================
# This function is called when the script is executed directly
# It parses command-line arguments and runs the appropriate processing mode
main() {
  # Initialize flags (0 = false, 1 = true in bash arithmetic)
  local use_jq_mode=0
  local show_help=0

  # -------------------------------------------------------------------------
  # Parse Command-Line Arguments
  # -------------------------------------------------------------------------
  # $# is the number of arguments
  # (( )) is arithmetic context - $# > 0 checks if arguments remain
  while (($# > 0)); do
    # case statement is like switch/case in other languages
    # $1 is the first argument
    case "$1" in
    --jq)
      # Enable JQ mode (faster but less formatting)
      use_jq_mode=1
      # shift removes $1 and moves remaining arguments down
      shift
      ;;
    -h | --help)
      # Show help message
      show_help=1
      shift
      ;;
    *)
      # Unknown option - this catches anything not matched above
      log_error "Unknown option: $1"
      show_help=1
      shift
      ;;
    esac
  done

  # -------------------------------------------------------------------------
  # Show Help if Requested
  # -------------------------------------------------------------------------
  if ((show_help == 1)); then
    cat <<'EOF'
sanity.sh - Log processing and pretty printing utility

Usage: 
  some_command | ./sanity.sh           # Process streaming logs
  ./sanity.sh < logfile.log            # Process log file
  ./sanity.sh --jq < logfile.log       # Use pure JQ mode (faster)

Options:
  --jq        Use pure JQ processing (faster, less formatting)
  -h, --help  Show this help message

Environment Variables:
  FX_LOGS       Show framework [Fx] logs (default: false)
  DEBUG_PREFIX  If set, only show logs with matching prefix or warnings/errors

Features:
  - Pretty prints JSON logs with indentation
  - Extracts and color-codes stack traces from error objects
  - Conditionally filters FX framework logs ([Fx] hidden by default)
  - Supports DEBUG_PREFIX filtering for selective log display

Examples:
  # Stream application logs with formatting
  go run cmd/main.go | ./sanity.sh

  # Process existing log file
  cat /var/log/app.log | ./sanity.sh

  # Show FX framework logs
  FX_LOGS=true go run cmd/main.go | ./sanity.sh

  # Filter to only show errors and specific prefix
  DEBUG_PREFIX="auth" cat app.log | ./sanity.sh
EOF
    # Exit with success status after showing help
    exit 0
  fi

  # -------------------------------------------------------------------------
  # Choose and Run Processing Mode
  # -------------------------------------------------------------------------
  # Based on the flags parsed above, run the appropriate mode
  if ((use_jq_mode == 1)); then
    # Fast mode: pure JQ processing (no color coding)
    process_logs_with_jq
  else
    # Standard mode: full bash processing with colors and stacktrace extraction
    process_logs
  fi

  return 0
}

# =============================================================================
# Script Execution Guard
# =============================================================================
# This checks if the script is being executed directly vs being sourced
# BASH_SOURCE[0] is the filename of the script
# $0 is the name of the running script
# If they match, the script was executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Call main function and pass all command-line arguments
  # "$@" expands to all arguments as separate quoted strings
  main "$@"
fi
