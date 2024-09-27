#!/bin/bash

# Path to the actual chrome executable
CMD="/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta"

# TODO: Create a new chrome profile that you'll use for dev
# then visit chrome://version and use the value of "Profile Path" here
PROFILE_PATH="/Users/mac/Library/Application Support/Google/Chrome Beta/Default"

PROFILE_DIRECTORY="${PROFILE_PATH##*/}"
USER_DATA_DIR="${PROFILE_PATH%/*}"

# Used to handle termination later
chrome_pid=""

# To launch Chrome in the background and capture PID for termination later
launch_chrome() {
  local filtered_params=("$@")
  "$CMD" --user-data-dir="$USER_DATA_DIR" --profile-directory="$PROFILE_DIRECTORY" "${filtered_params[@]}" &
  chrome_pid=$!
  sleep 0.1 # Brief sleep to avoid race condition with signal trapping
}

# To terminate Chrome when this script receives a termination signal
terminate_chrome() {
  if [ -n "$chrome_pid" ]; then
    kill -TERM "$chrome_pid" 2>/dev/null
    wait "$chrome_pid" 2>/dev/null
    chrome_pid=""
  fi
}

# Trap termination signals and ensure Chrome is terminated properly
trap 'terminate_chrome; exit $?' INT TERM HUP QUIT

# Check if Chrome is already running with the specified profile
if pgrep -f "$CMD --profile-directory=$PROFILE_DIRECTORY" >/dev/null; then
  echo "Chrome is already running with the specified profile."
  exit 1
fi

if [ "$1" == "--version" ]; then
  # Flutter calls --version first
  "$CMD" --version
else
  params=("$@")
  exclusions=("disable-extensions" "bwsi" "user-data-dir=")
  filtered_params=()

  for param in "${params[@]}"; do
    skip=false
    for exclude in "${exclusions[@]}"; do
      if [[ "$param" == --$exclude* ]]; then
        skip=true
        break
      fi
    done
    if [ "$skip" == false ]; then
      filtered_params+=("$param")
    fi
  done

  # Launch Chrome and capture PID to use for termination later
  launch_chrome "${filtered_params[@]}"
fi

# Keep script running in the background to listen for when flutter tries to terminate Chrome ("q", "Q", Ctrl+C, etc.)
wait
