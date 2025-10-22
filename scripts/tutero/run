#!/usr/bin/env bash
set -euo pipefail

readonly CONFIG_DEFAULT="config.yml"
readonly FIREBASE_SECRET="/Users/mac/Coding/metarepo/backend/app/resources/secrets/sa-app.json"
readonly SERVICE_DEFAULT=""
readonly DEFAULT_GRAPHQL_PORT=8087
readonly DEFAULT_GRPC_PORT=50054
readonly CACHE_TTL_SECONDS=120
readonly CACHE_DIR="${HOME}/.cache/scripts"
readonly CACHE_FILE="${CACHE_DIR}/resources-server.json"
readonly CACHE_LOCK_FILE="${CACHE_FILE}.lock"
readonly BOOT_CACHE_FILE="${CACHE_DIR}/resources-boot-estimates.json"
readonly SERVICE_READY_PATTERN='^\[Fx\][[:space:]]+RUNNING'
readonly TELEPRESENCE_ROUTER_URL="http://cosmo-router.infrastructure.svc.cluster.local:3002/"
readonly REQUIRED_COMMANDS=(jq lsof telepresence go flock)

declare CACHE_LOCK_FD=""
declare -i INTERRUPT_COUNT=0
declare -i GRAPHQL_PORT=0
declare -i GRPC_PORT=0
declare -i GO_PID=0
declare -a GO_ARGS=()
declare -a ENV_VARS=()

LOG_PIPE=""
LOG_PIPE_DIR=""
BRANCH=""
CONFIG_SOURCE=""
CONFIG_OVERRIDE=""
CONFIG_COPY=""
SERVICE_DISPLAY="$SERVICE_DEFAULT"
BOOT_START=0
OTEL_MODE=0
ESTIMATE_ONLY=0

read -r -d '' JQ_PROGRAM <<'JQ' || true
select(
  (test("^::") | not)
  and (test("^\\[F[0-9x]\\]") | not)
  and (test("^redis:") | not)
)
| . as $raw
| try fromjson catch $raw
| if (type == "object" and has("stacktrace")) then
    (del(.stacktrace) | to_entries[] | "\(.key): \(.value)"),
    "stacktrace:",
    (.stacktrace | split("\n") | map("  " + .) | .[])
  else
    .
  end
JQ

usage() {
  cat <<'EOF'
Usage: run [-otel] [--estimate-only] [config_file] [-- go-args...]
  -otel              Export SERVICE_NAME (if unset) for Otel instrumentation.
  --estimate-only    Print boot time estimate and exit (dry-run).
  config_file        Optional override for the config file path.
  --                 Pass subsequent arguments directly to go.
EOF
}

log_info() {
  printf ':: %s\n' "$*"
}

log_error() {
  printf ':: %s\n' "$*" >&2
}

die() {
  log_error "$1"
  exit 1
}

require_commands() {
  local missing=()
  local cmd
  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if ((${#missing[@]} > 0)); then
    local joined
    printf -v joined '%s, ' "${missing[@]}"
    joined=${joined%, }
    die "Missing required command(s): ${joined}"
  fi
}

parse_args() {
  CONFIG_SOURCE="${CONFIG_FILE:-$CONFIG_DEFAULT}"
  while (($# > 0)); do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -otel)
      OTEL_MODE=1
      shift
      ;;
    --estimate-only)
      ESTIMATE_ONLY=1
      shift
      ;;
    --)
      shift
      GO_ARGS=("$@")
      break
      ;;
    -*)
      die "Unknown option $1"
      ;;
    *)
      if [[ -z "$CONFIG_OVERRIDE" ]]; then
        CONFIG_OVERRIDE=$1
        CONFIG_SOURCE=$CONFIG_OVERRIDE
      else
        GO_ARGS+=("$1")
      fi
      shift
      ;;
    esac
  done

  if ((${#GO_ARGS[@]} == 0)); then
    GO_ARGS=(run cmd/main.go)
  fi
}

verify_inputs() {
  [[ -f "$CONFIG_SOURCE" ]] || die "Config file $CONFIG_SOURCE not found"
  [[ -f "$FIREBASE_SECRET" ]] || die "firebaseServiceAccount secret not found at $FIREBASE_SECRET"
}

sanitize_branch() {
  local branch=$1
  branch=${branch// /-}
  branch=${branch//\//-}
  branch=${branch//[^[:alnum:]-_]/-}
  branch=${branch#-}
  branch=${branch%-}
  if [[ -z "$branch" ]]; then
    branch="default"
  fi
  printf '%s\n' "$branch"
}

determine_branch() {
  local raw_branch
  raw_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
  BRANCH=$(sanitize_branch "$raw_branch")
}

current_epoch() {
  date +%s
}

register_pipe_dir() {
  LOG_PIPE_DIR=$(mktemp -d)
  LOG_PIPE="${LOG_PIPE_DIR}/service.log"
  mkfifo -- "$LOG_PIPE"
}

prepare_cache() {
  mkdir -p "$CACHE_DIR"
  if [[ ! -f "$CACHE_FILE" ]]; then
    printf '{"entries":[]}\n' >"$CACHE_FILE"
  fi
  if [[ ! -f "$BOOT_CACHE_FILE" ]]; then
    printf '{"builds":[],"probes":[],"estimates":[]}\n' >"$BOOT_CACHE_FILE"
  fi
  exec {CACHE_LOCK_FD}>"$CACHE_LOCK_FILE"
}

ports_active() {
  local graphql=$1
  local grpc=$2
  if lsof -i:"$graphql" -t >/dev/null 2>&1; then
    return 0
  fi
  if lsof -i:"$grpc" -t >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

prune_cache() {
  local now tmp_entries entry graphql grpc claimed keep age
  now=$(current_epoch)
  tmp_entries=$(mktemp)

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    graphql=$(jq -r '.graphql_port' <<<"$entry")
    grpc=$(jq -r '.grpc_port' <<<"$entry")
    claimed=$(jq -r '.claimed_at // .timestamp // 0' <<<"$entry")
    keep=0

    if ports_active "$graphql" "$grpc"; then
      keep=1
    else
      age=$((now - claimed))
      if ((age <= CACHE_TTL_SECONDS)); then
        keep=1
      fi
    fi

    if ((keep == 1)); then
      printf '%s\n' "$entry" >>"$tmp_entries"
    fi
  done < <(jq -c '.entries[]?' "$CACHE_FILE" 2>/dev/null || true)

  if [[ -s "$tmp_entries" ]]; then
    jq -s '{entries: .}' "$tmp_entries" >"$CACHE_FILE"
  else
    printf '{"entries":[]}\n' >"$CACHE_FILE"
  fi

  rm -f "$tmp_entries"
}

load_branch_entry() {
  jq -c --arg branch "$BRANCH" '.entries[]? | select(.branch == $branch)' "$CACHE_FILE"
}

update_cache_entry() {
  local graphql=$1
  local grpc=$2
  local now tmp
  now=$(current_epoch)
  tmp=$(mktemp)
  jq --arg branch "$BRANCH" \
    --argjson gql "$graphql" \
    --argjson grpc "$grpc" \
    --argjson ts "$now" \
    '
       .entries
       | map(select(.branch != $branch)) as $others
       | {entries: ($others + [{branch: $branch, graphql_port: $gql, grpc_port: $grpc, claimed_at: $ts}])}
     ' "$CACHE_FILE" >"$tmp"
  mv "$tmp" "$CACHE_FILE"
}

allocate_ports() {
  local entry gql_candidate grpc_candidate n conflict
  flock "$CACHE_LOCK_FD"
  prune_cache
  entry=$(load_branch_entry)
  if [[ -n "$entry" ]]; then
    GRAPHQL_PORT=$(jq -r '.graphql_port' <<<"$entry")
    GRPC_PORT=$(jq -r '.grpc_port' <<<"$entry")
    update_cache_entry "$GRAPHQL_PORT" "$GRPC_PORT"
    flock -u "$CACHE_LOCK_FD"
    return
  fi

  n=0
  while true; do
    gql_candidate=$((DEFAULT_GRAPHQL_PORT + n))
    grpc_candidate=$((DEFAULT_GRPC_PORT + n))
    conflict=$(jq --arg branch "$BRANCH" --argjson gql "$gql_candidate" --argjson grpc "$grpc_candidate" '
      any(.entries[]?;
        (.branch != $branch) and
        (.graphql_port == $gql or .grpc_port == $grpc)
      )
    ' "$CACHE_FILE")
    if [[ "$conflict" != "true" ]] && ! ports_active "$gql_candidate" "$grpc_candidate"; then
      GRAPHQL_PORT=$gql_candidate
      GRPC_PORT=$grpc_candidate
      update_cache_entry "$GRAPHQL_PORT" "$GRPC_PORT"
      flock -u "$CACHE_LOCK_FD"
      return
    fi
    n=$((n + 1))
  done
}

ensure_config_copy() {
  local config_basename extension base
  config_basename=$(basename "$CONFIG_SOURCE")
  extension="${config_basename##*.}"
  if [[ "$config_basename" == "$extension" ]]; then
    CONFIG_COPY="/tmp/${config_basename}-${BRANCH}.yml"
  else
    base="${config_basename%.*}"
    CONFIG_COPY="/tmp/${base}-${BRANCH}.${extension}"
  fi

  cp "$CONFIG_SOURCE" "$CONFIG_COPY"
  ensure_config_ports "$CONFIG_COPY"
}

ensure_config_ports() {
  local file=$1
  local tmp
  tmp=$(mktemp)
  awk -v secret="$FIREBASE_SECRET" -v gql="$GRAPHQL_PORT" -v grpc="$GRPC_PORT" '
    {
      if ($0 ~ /^graphql:/) {
        section="graphql"
      } else if ($0 ~ /^grpc:/) {
        section="grpc"
      } else if ($0 ~ /^firebase:/) {
        section="firebase"
      } else if ($0 ~ /^[^[:space:]]/) {
        section=""
      }

      if (section=="graphql" && $0 ~ /^[[:space:]]+port:[[:space:]]*/) {
        sub(/port:.*/, "port: " gql)
        section=""
      } else if (section=="grpc" && $0 ~ /^[[:space:]]+port:[[:space:]]*/) {
        sub(/port:.*/, "port: " grpc)
        section=""
      } else if (section=="firebase" && $0 ~ /^[[:space:]]+firebaseServiceAccount:[[:space:]]*/) {
        sub(/firebaseServiceAccount:.*/, "firebaseServiceAccount: " secret)
        section=""
      }

      print
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

kill_port() {
  local port=$1
  local -a pids=()
  mapfile -t pids < <(lsof -i:"$port" -t 2>/dev/null || true)
  if ((${#pids[@]} == 0)); then
    return
  fi

  local pid
  for pid in "${pids[@]}"; do
    if kill -9 "$pid" 2>/dev/null; then
      log_info "Killed PID $pid"
    else
      log_info "Failed to kill PID $pid"
    fi
  done
  sleep 1
}

compute_go_hash() {
  local hash=""
  if [[ -d "./cmd" ]] || [[ -d "./internal" ]]; then
    hash=$(find ./cmd ./internal -type f -name "*.go" -exec stat -f "%m" {} \; 2>/dev/null | sort | md5sum 2>/dev/null || echo "")
    hash=${hash%% *}
  fi
  printf '%s\n' "$hash"
}

determine_boot_profile() {
  local cached_hash current_hash
  cached_hash=$(jq -r '.builds[-1].hash // ""' "$BOOT_CACHE_FILE" 2>/dev/null || echo "")
  current_hash=$(compute_go_hash)

  if [[ -z "$current_hash" ]] || [[ "$current_hash" != "$cached_hash" ]]; then
    printf 'has_changes\n'
  else
    printf 'no_changes\n'
  fi
}

check_service_reachable() {
  local url="${1:-$TELEPRESENCE_ROUTER_URL}"
  local rc
  curl -fsS --max-time 3 -o /dev/null "$url" 2>/dev/null
  rc=$?
  [[ $rc -eq 0 || $rc -eq 22 ]]
}

telepresence_health() {
  local start_time end_time latency_ms

  if command -v gdate >/dev/null 2>&1; then
    start_time=$(gdate +%s%3N)
  else
    start_time=$(($(date +%s) * 1000))
  fi

  if check_service_reachable "$TELEPRESENCE_ROUTER_URL"; then
    if command -v gdate >/dev/null 2>&1; then
      end_time=$(gdate +%s%3N)
    else
      end_time=$(($(date +%s) * 1000))
    fi
    latency_ms=$((end_time - start_time))
    if ((latency_ms < 500)); then
      printf 'connected %d\n' "$latency_ms"
    else
      printf 'degraded %d\n' "$latency_ms"
    fi
  else
    printf 'offline 0\n'
  fi
}

compute_boot_estimate() {
  local profile=$1
  local telepresence_state=$2
  local base_estimate addon

  if [[ "$profile" == "no_changes" ]]; then
    base_estimate=12
  else
    base_estimate=20
  fi

  addon=0
  if [[ "$telepresence_state" == "offline" ]]; then
    addon=15
  elif [[ "$telepresence_state" == "degraded" ]]; then
    addon=0
  fi

  local avg_estimate
  avg_estimate=$(jq -r '.estimates[-5:] | if length > 0 then (add / length | floor) else 0 end' "$BOOT_CACHE_FILE" 2>/dev/null || echo "0")

  if ((avg_estimate > 0)); then
    base_estimate=$(((base_estimate + avg_estimate) / 2))
  fi

  printf '%d\n' "$((base_estimate + addon))"
}

record_boot_estimate() {
  local actual_duration=$1
  local tmp
  tmp=$(mktemp)
  jq --argjson duration "$actual_duration" \
    --argjson ts "$(current_epoch)" \
    '.estimates += [$duration] | .estimates = .estimates[-10:]' \
    "$BOOT_CACHE_FILE" >"$tmp"
  mv "$tmp" "$BOOT_CACHE_FILE"
}

record_build_hash() {
  local current_hash=$1
  local tmp
  tmp=$(mktemp)
  jq --arg hash "$current_hash" \
    --argjson ts "$(current_epoch)" \
    '.builds += [{hash: $hash, timestamp: $ts}] | .builds = .builds[-5:]' \
    "$BOOT_CACHE_FILE" >"$tmp"
  mv "$tmp" "$BOOT_CACHE_FILE"
}

get_adaptive_boot_estimate() {
  local profile telepresence_status latency estimate
  profile=$(determine_boot_profile)
  read -r telepresence_status latency < <(telepresence_health)
  estimate=$(compute_boot_estimate "$profile" "$telepresence_status")

  if ((ESTIMATE_ONLY == 1)); then
    printf 'Estimated boot time: %ds\n' "$estimate"
    printf '  Build profile: %s\n' "$profile"
    printf '  Telepresence: %s\n' "$telepresence_status"
    if [[ "$telepresence_status" != "offline" ]]; then
      printf '  Latency: %dms\n' "$latency"
    fi
    exit 0
  fi

  printf '%s %s %d\n' "$profile" "$telepresence_status" "$estimate"
}

prepare_env() {
  local config_display
  if [[ -z "${CONFIG_FILE:-}" ]]; then
    ENV_VARS+=(CONFIG_FILE="$CONFIG_COPY")
    config_display="$CONFIG_COPY"
  else
    config_display=$CONFIG_FILE
  fi

  if ((OTEL_MODE == 1)) && [[ -z "${SERVICE_NAME:-}" ]]; then
    ENV_VARS+=(SERVICE_NAME="$SERVICE_DEFAULT")
    SERVICE_DISPLAY="$SERVICE_DEFAULT"
  elif ((OTEL_MODE == 1)); then
    SERVICE_DISPLAY=$SERVICE_NAME
  else
    SERVICE_DISPLAY="${SERVICE_NAME:-$SERVICE_DEFAULT}"
  fi

  if [[ -n "${TEST_DEBUG:-}" ]]; then
    ENV_VARS+=(TEST_DEBUG="$TEST_DEBUG")
    log_info "TEST_DEBUG=$TEST_DEBUG enabled"
  fi

  log_info "branch=${BRANCH} -- graphql:grpc ${GRAPHQL_PORT}:${GRPC_PORT}"
  log_info "firebaseServiceAccount=${FIREBASE_SECRET}"
  log_info "SERVICE_NAME=${SERVICE_DISPLAY}, CONFIG_FILE=${config_display}"
}

print_boot_estimate() {
  local boot_profile tele_status boot_estimate
  read -r boot_profile tele_status boot_estimate < <(get_adaptive_boot_estimate)
  log_info "Starting with \`go ${GO_ARGS[*]}\`, Boot estimate: ${boot_estimate}s (code compilation=${boot_profile}, telepresence=${tele_status})"
}

ensure_telepresence() {
  if ! check_service_reachable "$TELEPRESENCE_ROUTER_URL"; then
    log_info "Telepresence not connected, connecting..."
    telepresence connect
  fi
}

format_service_line() {
  local line=$1

  if printf '%s' "$line" | jq empty 2>/dev/null; then
    local has_error_stack
    has_error_stack=$(printf '%s' "$line" | jq -r 'if type == "object" and has("error") and (.error | type == "object" and has("stacktrace")) then "yes" else "no" end' 2>/dev/null || echo "no")

    if [[ "$has_error_stack" == "yes" ]]; then
      local stacktrace without_stack formatted_stack
      stacktrace=$(printf '%s' "$line" | jq -r '.error.stacktrace')
      without_stack=$(printf '%s' "$line" | jq 'del(.error.stacktrace)')

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

      printf '%s\n' "$without_stack" | jq --indent 2 .
      printf '\033[1;33mFormatted Stacktrace:\033[0m\n'
      printf '%s\n' "$formatted_stack"
    else
      printf '%s\n' "$line" | jq --indent 2 .
    fi
  else
    printf '%s\n' "$line"
  fi
}

handle_service_output() {
  local started_reported=0
  local line boot_end boot_time current_hash
  while IFS= read -r line || [[ -n "$line" ]]; do
    if ((started_reported == 0)) && [[ $line =~ $SERVICE_READY_PATTERN ]]; then
      boot_end=$(current_epoch)
      boot_time=$((boot_end - BOOT_START))
      log_info "We're UP and RUNNING [branch=${BRANCH}, graphql=${GRAPHQL_PORT}, grpc=${GRPC_PORT}] (boot time: ${boot_time}s)"
      started_reported=1

      record_boot_estimate "$boot_time"
      current_hash=$(compute_go_hash)
      if [[ -n "$current_hash" ]]; then
        record_build_hash "$current_hash"
      fi
      continue
    fi

    if [[ $line =~ ^:: ]] || [[ $line =~ ^\[F[0-9x]\] ]] || [[ $line =~ ^redis: ]]; then
      continue
    fi

    format_service_line "$line"
  done <"$LOG_PIPE"
}

start_service_process() {
  register_pipe_dir
  local -a run_cmd=("go" "${GO_ARGS[@]}")
  if ((${#ENV_VARS[@]} > 0)); then
    run_cmd=("env" "${ENV_VARS[@]}" "${run_cmd[@]}")
  fi
  if command -v stdbuf >/dev/null 2>&1; then
    run_cmd=("stdbuf" "-oL" "${run_cmd[@]}")
  fi

  "${run_cmd[@]}" >"$LOG_PIPE" 2>&1 &
  GO_PID=$!
}

# shellcheck disable=SC2329
handle_interrupt() {
  INTERRUPT_COUNT=$((INTERRUPT_COUNT + 1))
  if ((INTERRUPT_COUNT == 1)); then
    log_info "Interrupt received, attempting graceful shutdown..."
    if ((GO_PID > 0)); then
      kill -INT "$GO_PID" 2>/dev/null || true
    fi
  elif ((INTERRUPT_COUNT == 2)); then
    log_info "Second interrupt detected, escalating termination..."
    if ((GO_PID > 0)); then
      kill -TERM "$GO_PID" 2>/dev/null || true
    fi
  else
    log_info "Force killing service (Ctrl-C x${INTERRUPT_COUNT})..."
    if ((GO_PID > 0)); then
      kill -KILL "$GO_PID" 2>/dev/null || true
    fi
    if ((GRAPHQL_PORT > 0)); then
      kill_port "$GRAPHQL_PORT"
    fi
    if ((GRPC_PORT > 0)); then
      kill_port "$GRPC_PORT"
    fi
  fi
}

# shellcheck disable=SC2329
cleanup() {
  local exit_status=$?
  if ((GO_PID > 0)); then
    kill "$GO_PID" 2>/dev/null || true
    wait "$GO_PID" 2>/dev/null || true
  fi
  if [[ -n "$LOG_PIPE" && -p "$LOG_PIPE" ]]; then
    rm -f "$LOG_PIPE"
  fi
  if [[ -n "$LOG_PIPE_DIR" && -d "$LOG_PIPE_DIR" ]]; then
    rm -rf "$LOG_PIPE_DIR"
  fi
  if [[ -n "${CACHE_LOCK_FD:-}" ]]; then
    exec {CACHE_LOCK_FD}>&-
    CACHE_LOCK_FD=""
  fi
  exit "$exit_status"
}

main() {
  parse_args "$@"
  require_commands
  verify_inputs
  determine_branch
  prepare_cache
  allocate_ports
  ensure_config_copy
  kill_port "$GRAPHQL_PORT"
  kill_port "$GRPC_PORT"
  prepare_env
  print_boot_estimate
  ensure_telepresence
  BOOT_START=$(current_epoch)
  start_service_process
  handle_service_output &
  local log_pid=$!
  wait "$GO_PID"
  local go_status=$?
  GO_PID=0
  wait "$log_pid" || true
  exit "$go_status"
}

trap cleanup EXIT
trap handle_interrupt INT TERM

main "$@"
