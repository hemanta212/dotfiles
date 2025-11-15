#!/usr/bin/env bash
# Summary: Watches resources-graphql pods and alerts when CPU usage exceeds 60% of the limit.
# Description:
# Uses kubectl top pods for the learning namespace, calculates percent of the 300m CPU limit, and logs color-coded statuses.
# Keeps a list of alerted pods to avoid spamming notifications and clears entries when values drop below threshold.
# Sends macOS notifications via osascript and prints warnings when CPU approaches higher bounds.
# Loops every 15 seconds, verifies namespace access before starting, and traps INT/TERM for a graceful shutdown.


# Monitor resources-graphql pods CPU usage and alert when over 60%
# Usage: ./monitor-cpu.sh

set -euo pipefail

# Config
NAMESPACE="learning"
DEPLOYMENT="resources-graphql"
CPU_LIMIT=300  # 300m
CPU_THRESHOLD=60  # Alert at 60% of limit (180m)
CHECK_INTERVAL=15  # seconds

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track alerted pods to avoid spam (space-separated list)
ALERTED_PODS=""

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

is_alerted() {
    local pod=$1
    echo "$ALERTED_PODS" | grep -qw "$pod"
}

add_alert() {
    local pod=$1
    ALERTED_PODS="$ALERTED_PODS $pod"
}

remove_alert() {
    local pod=$1
    ALERTED_PODS=$(echo "$ALERTED_PODS" | sed "s/\b$pod\b//g" | xargs)
}

send_alert() {
    local pod=$1
    local cpu=$2
    local percent=$3
    
    local message="⚠️  CPU Alert: $pod at ${cpu}m (${percent}%)"
    
    # macOS notification
    osascript -e "display notification \"$message\" with title \"K8s CPU Alert\" sound name \"Basso\"" 2>/dev/null || true
    
    log "${RED}${message}${NC}"
}

clear_alert() {
    local pod=$1
    local cpu=$2
    local percent=$3
    
    if is_alerted "$pod"; then
        log "${GREEN}✓ $pod recovered: ${cpu}m (${percent}%)${NC}"
        remove_alert "$pod"
    fi
}

check_pods() {
    local threshold_cpu=$((CPU_LIMIT * CPU_THRESHOLD / 100))
    
    # Get pod CPU usage
    local pods_data
    pods_data=$(kubectl top pods -n "$NAMESPACE" -l "app=$DEPLOYMENT" --no-headers 2>/dev/null) || {
        log "${RED}Error: Failed to get pod metrics${NC}"
        return 1
    }
    
    if [[ -z "$pods_data" ]]; then
        log "${YELLOW}Warning: No pods found${NC}"
        return 0
    fi
    
    # Parse each pod
    while IFS= read -r line; do
        local pod_name=$(echo "$line" | awk '{print $1}')
        local cpu_usage=$(echo "$line" | awk '{print $2}')
        
        # Extract numeric value (e.g., "304m" -> 304)
        local cpu_value=${cpu_usage%m}
        
        # Calculate percentage
        local cpu_percent=$((cpu_value * 100 / CPU_LIMIT))
        
        # Check threshold
        if [[ $cpu_value -gt $threshold_cpu ]]; then
            # Alert if not already alerted
            if ! is_alerted "$pod_name"; then
                send_alert "$pod_name" "$cpu_value" "$cpu_percent"
                add_alert "$pod_name"
            fi
        else
            # Clear alert if previously alerted
            clear_alert "$pod_name" "$cpu_value" "$cpu_percent"
        fi
        
        # Log status
        if [[ $cpu_percent -gt 80 ]]; then
            log "${RED}🔴 $pod_name: ${cpu_value}m (${cpu_percent}%)${NC}"
        elif [[ $cpu_percent -gt 60 ]]; then
            log "${YELLOW}🟡 $pod_name: ${cpu_value}m (${cpu_percent}%)${NC}"
        else
            log "${GREEN}🟢 $pod_name: ${cpu_value}m (${cpu_percent}%)${NC}"
        fi
        
    done <<< "$pods_data"
}

main() {
    local threshold_value=$((CPU_LIMIT * CPU_THRESHOLD / 100))
    log "🚀 Starting CPU monitor for $DEPLOYMENT pods in $NAMESPACE namespace"
    log "📊 CPU Limit: ${CPU_LIMIT}m | Alert Threshold: ${CPU_THRESHOLD}% (${threshold_value}m)"
    log "⏱️  Check Interval: ${CHECK_INTERVAL}s"
    echo ""
    
    # Check kubectl access
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log "${RED}Error: Cannot access namespace $NAMESPACE${NC}"
        exit 1
    fi
    
    # Main loop
    while true; do
        check_pods
        echo ""
        sleep "$CHECK_INTERVAL"
    done
}

# Handle Ctrl+C gracefully
trap 'log "Stopping monitor..."; exit 0' INT TERM

main "$@"
