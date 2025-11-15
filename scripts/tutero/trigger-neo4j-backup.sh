#!/bin/bash

# Script to trigger and monitor Neo4j backups across prod and prod-us contexts
# Usage: ./trigger-backup.sh [cronjob-name] [namespace]
# Example: ./trigger-backup.sh learning-neo4j-backup learning

set -e

# Configuration
CRONJOB_NAME="${1:-learning-neo4j-backup}"
NAMESPACE="${2:-learning}"
CONTEXTS=("prod" "prod-us")
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if cronjob exists
check_cronjob() {
    local context=$1
    if ! kubectl get cronjob "$CRONJOB_NAME" -n "$NAMESPACE" --context "$context" &> /dev/null; then
        print_error "CronJob '$CRONJOB_NAME' not found in namespace '$NAMESPACE' on context '$context'"
        return 1
    fi
    return 0
}

# Function to trigger backup job
trigger_backup() {
    local context=$1
    local job_name="${CRONJOB_NAME}-manual-${TIMESTAMP}-${context}"
    
    print_info "Triggering backup on $context: $job_name"
    
    if kubectl create job --from=cronjob/"$CRONJOB_NAME" "$job_name" -n "$NAMESPACE" --context "$context" &> /dev/null; then
        print_success "Backup job created on $context: $job_name"
        echo "$job_name"
    else
        print_error "Failed to create backup job on $context"
        return 1
    fi
}

# Function to get pod name for a job
get_pod_name() {
    local context=$1
    local job_name=$2
    local max_attempts=10
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local pod_name=$(kubectl get pods -n "$NAMESPACE" -l job-name="$job_name" --context "$context" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$pod_name" ]; then
            echo "$pod_name"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    return 1
}

# Function to check job status
check_job_status() {
    local context=$1
    local job_name=$2
    
    kubectl get job "$job_name" -n "$NAMESPACE" --context "$context" -o jsonpath='{.status.conditions[0].type}' 2>/dev/null
}

# Function to get job completion status
is_job_complete() {
    local context=$1
    local job_name=$2
    
    local status=$(check_job_status "$context" "$job_name")
    if [ "$status" == "Complete" ]; then
        return 0
    elif [ "$status" == "Failed" ]; then
        return 2
    else
        return 1
    fi
}

# Function to monitor job progress
monitor_job() {
    local context=$1
    local job_name=$2
    local pod_name=$3
    
    print_info "Monitoring $context: $job_name"
    
    while true; do
        if is_job_complete "$context" "$job_name"; then
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                print_success "$context: Backup completed successfully!"
                return 0
            elif [ $exit_code -eq 2 ]; then
                print_error "$context: Backup failed!"
                return 1
            fi
        fi
        
        # Show pod status
        local pod_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" --context "$context" -o jsonpath='{.status.phase}' 2>/dev/null)
        local container_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" --context "$context" -o jsonpath='{.status.containerStatuses[0].state}' 2>/dev/null)
        
        echo -ne "\r${BLUE}[$context]${NC} Pod: $pod_status | Status: $(echo $container_status | head -c 50)..."
        
        sleep 5
    done
}

# Function to get container status details
get_container_status() {
    local context=$1
    local pod_name=$2
    
    echo ""
    print_info "=== Container Status for $context ==="
    
    # Get init container status
    echo ""
    echo "Init Containers:"
    kubectl get pod "$pod_name" -n "$NAMESPACE" --context "$context" -o json 2>/dev/null | jq -r '
        .status.initContainerStatuses[]? | 
        "  • \(.name):" +
        (if .state.running then " RUNNING (started: \(.state.running.startedAt))"
         elif .state.terminated then " TERMINATED (exit: \(.state.terminated.exitCode), reason: \(.state.terminated.reason), started: \(.state.terminated.startedAt), finished: \(.state.terminated.finishedAt))"
         elif .state.waiting then " WAITING (reason: \(.state.waiting.reason // "Unknown"))"
         else " UNKNOWN"
         end)
    ' 2>/dev/null || echo "  No init containers found"
    
    # Get main container status
    echo ""
    echo "Main Containers:"
    kubectl get pod "$pod_name" -n "$NAMESPACE" --context "$context" -o json 2>/dev/null | jq -r '
        .status.containerStatuses[]? | 
        "  • \(.name):" +
        (if .state.running then " RUNNING (started: \(.state.running.startedAt))"
         elif .state.terminated then " TERMINATED (exit: \(.state.terminated.exitCode), reason: \(.state.terminated.reason), started: \(.state.terminated.startedAt), finished: \(.state.terminated.finishedAt))"
         elif .state.waiting then " WAITING (reason: \(.state.waiting.reason // "Unknown"))"
         else " UNKNOWN"
         end)
    ' 2>/dev/null || echo "  No main containers found"
    
    echo "----------------------------------------"
}

# Function to show logs
show_logs() {
    local context=$1
    local pod_name=$2
    
    print_info "Showing logs for $context:"
    echo "----------------------------------------"
    
    # Show init container logs (neo4j-backup)
    echo ""
    echo "[neo4j-backup container - last 15 lines]"
    kubectl logs "$pod_name" -n "$NAMESPACE" -c neo4j-backup --context "$context" --tail=15 2>/dev/null || echo "No logs available"
    
    echo ""
    echo "[gcs-fuse container - last 10 lines]"
    # Show main container logs (gcs-fuse)
    kubectl logs "$pod_name" -n "$NAMESPACE" -c gcs-fuse --context "$context" --tail=10 2>/dev/null || echo "No logs available"
    
    echo "----------------------------------------"
}

# Main execution
main() {
    print_info "=== Neo4j Backup Trigger Script ==="
    print_info "CronJob: $CRONJOB_NAME"
    print_info "Namespace: $NAMESPACE"
    print_info "Contexts: ${CONTEXTS[*]}"
    print_info "Timestamp: $TIMESTAMP"
    echo ""
    
    # Check if cronjobs exist in all contexts
    for context in "${CONTEXTS[@]}"; do
        if ! check_cronjob "$context"; then
            exit 1
        fi
    done
    
    print_success "CronJob found in all contexts"
    echo ""
    
    # Trigger backups on all contexts
    declare -A jobs
    declare -A pods
    
    for context in "${CONTEXTS[@]}"; do
        job_name=$(trigger_backup "$context")
        if [ $? -eq 0 ]; then
            jobs[$context]=$job_name
            
            # Get pod name
            print_info "Waiting for pod to be created on $context..."
            pod_name=$(get_pod_name "$context" "$job_name")
            if [ $? -eq 0 ]; then
                pods[$context]=$pod_name
                print_success "Pod created on $context: $pod_name"
            else
                print_error "Failed to get pod name on $context"
            fi
        fi
    done
    
    echo ""
    print_info "=== Monitoring Backup Progress ==="
    echo ""
    
    # Monitor all jobs in parallel
    pids=()
    for context in "${CONTEXTS[@]}"; do
        if [ -n "${jobs[$context]}" ] && [ -n "${pods[$context]}" ]; then
            (
                monitor_job "$context" "${jobs[$context]}" "${pods[$context]}"
                local exit_code=$?
                echo ""
                get_container_status "$context" "${pods[$context]}"
                echo ""
                show_logs "$context" "${pods[$context]}"
                exit $exit_code
            ) &
            pids+=($!)
        fi
    done
    
    # Wait for all monitoring processes to complete
    all_success=0
    for pid in "${pids[@]}"; do
        wait $pid
        if [ $? -ne 0 ]; then
            all_success=1
        fi
    done
    
    echo ""
    print_info "=== Backup Summary ==="
    
    for context in "${CONTEXTS[@]}"; do
        if [ -n "${jobs[$context]}" ]; then
            if is_job_complete "$context" "${jobs[$context]}"; then
                if [ $? -eq 0 ]; then
                    print_success "$context: ${jobs[$context]} - COMPLETED"
                else
                    print_error "$context: ${jobs[$context]} - FAILED"
                fi
            else
                print_warning "$context: ${jobs[$context]} - STILL RUNNING"
            fi
        fi
    done
    
    echo ""
    print_info "Job names for reference:"
    for context in "${CONTEXTS[@]}"; do
        if [ -n "${jobs[$context]}" ]; then
            echo "  $context: ${jobs[$context]}"
        fi
    done
    
    echo ""
    print_info "To view logs later, use:"
    for context in "${CONTEXTS[@]}"; do
        if [ -n "${pods[$context]}" ]; then
            echo "  kubectl logs ${pods[$context]} -n $NAMESPACE -c neo4j-backup --context $context"
        fi
    done
    
    exit $all_success
}

# Run main function
main
