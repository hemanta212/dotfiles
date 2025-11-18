#!/bin/bash

# System Monitor Script for macOS
# Monitors CPU, RAM, and temperature with audio alerts via piper-say
# Detects sustained temperature spikes (85°C+ occurring 3-5 times)
# -d flag: Kill previously logged problematic processes

set -euo pipefail

# Configuration
CPU_THRESHOLD=80          # Individual process CPU usage percentage threshold
RAM_THRESHOLD=15          # Individual process RAM usage percentage threshold
TEMP_THRESHOLD=85         # Temperature threshold in Celsius
TEMP_SPIKE_COUNT=3        # Number of sustained spikes before alerting
CHECK_INTERVAL=5          # Seconds between checks
MAX_PROCESSES=5           # Number of top processes to report

# State tracking
TEMP_SPIKE_COUNTER=0
TEMP_ALERT_TRIGGERED=false
LAST_CPU_ALERT_TIME=0
LAST_RAM_ALERT_TIME=0
ALERT_COOLDOWN=300        # 5 minutes between same type of alerts

# Daemon mode flag
DAEMON_KILL_MODE=false

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file and PID tracking directory
LOG_FILE="$HOME/system_monitor.log"
PID_LOG_DIR="$HOME/.cache/scripts/monitor/pids"
PID_LOG_FILE="$PID_LOG_DIR/problematic_pids.log"

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [-d] [-h]

Options:
    -d    Daemon kill mode: Kill all previously logged problematic processes
    -h    Show this help message

Without -d: Monitor system and log problematic processes
With -d: Kill all processes logged in previous monitoring sessions
EOF
}

# Function to initialize PID log directory
init_pid_log_dir() {
    if [ ! -d "$PID_LOG_DIR" ]; then
        mkdir -p "$PID_LOG_DIR"
        echo -e "${GREEN}Created PID log directory: $PID_LOG_DIR${NC}"
    fi
}

# Function to log problematic process
log_problematic_pid() {
    local pid="$1"
    local process_name="$2"
    local reason="$3"
    local usage="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create entry
    echo "$timestamp|$pid|$process_name|$reason|$usage" >> "$PID_LOG_FILE"
    echo -e "${BLUE}📝 Logged: PID $pid ($process_name) - $reason at $usage${NC}"
}

# Function to kill logged processes
kill_logged_processes() {
    if [ ! -f "$PID_LOG_FILE" ]; then
        echo -e "${YELLOW}No logged processes found at: $PID_LOG_FILE${NC}"
        if command -v piper-say &> /dev/null; then
            piper-say "No logged processes found" &
        fi
        exit 0
    fi
    
    echo -e "${RED}🔪 Daemon Kill Mode Activated${NC}"
    echo "Reading logged processes from: $PID_LOG_FILE"
    echo ""
    
    local killed_count=0
    local not_found_count=0
    local failed_count=0
    
    while IFS='|' read -r timestamp pid process_name reason usage; do
        # Check if process still exists
        if ps -p "$pid" > /dev/null 2>&1; then
            local current_name
            current_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
            echo -e "${YELLOW}Found: PID $pid ($current_name)${NC}"
            echo "  Originally logged: $timestamp"
            echo "  Reason: $reason at $usage"
            
            # Try to kill the process
            if kill "$pid" 2>/dev/null; then
                echo -e "${GREEN}  ✓ Killed successfully${NC}"
                ((killed_count++))
            else
                echo -e "${RED}  ✗ Failed to kill (may require sudo)${NC}"
                ((failed_count++))
            fi
        else
            echo -e "${BLUE}Not running: PID $pid ($process_name)${NC}"
            ((not_found_count++))
        fi
        echo ""
    done < "$PID_LOG_FILE"
    
    # Summary
    echo "========================================"
    echo "Kill Summary:"
    echo "  Killed: $killed_count"
    echo "  Not found: $not_found_count"
    echo "  Failed: $failed_count"
    echo "========================================"
    
    # Archive the log file
    local archive_name
    archive_name="$PID_LOG_FILE.$(date '+%Y%m%d_%H%M%S').archive"
    mv "$PID_LOG_FILE" "$archive_name"
    echo -e "${GREEN}Archived log to: $archive_name${NC}"
    
    if command -v piper-say &> /dev/null; then
        piper-say "Killed $killed_count processes. $failed_count failed." &
    fi
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    # Check for temperature monitoring tool (smctemp works on both Intel and Apple Silicon)
    if ! command -v smctemp &> /dev/null; then
        echo -e "${YELLOW}Installing smctemp for temperature monitoring...${NC}"
        if command -v brew &> /dev/null; then
            brew tap narugit/tap 2>&1 | grep -v "Warning"
            brew install narugit/tap/smctemp
            echo -e "${GREEN}smctemp installed successfully${NC}"
        else
            echo -e "${RED}Homebrew not found. Cannot install smctemp.${NC}"
            echo "Install Homebrew from https://brew.sh"
            exit 1
        fi
    fi
    
    if ! command -v piper-say &> /dev/null; then
        echo -e "${YELLOW}Warning: piper-say not found. Audio alerts will be disabled.${NC}"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing_deps[*]}${NC}"
        echo "Install with: brew install ${missing_deps[*]}"
        echo ""
        read -p "Install missing dependencies now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install "${missing_deps[@]}"
        else
            echo "Exiting. Please install dependencies manually."
            exit 1
        fi
    fi
}

# Function to send audio alert
send_alert() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: $message" >> "$LOG_FILE"
    echo -e "${RED}🚨 ALERT: $message${NC}"
    
    if command -v piper-say &> /dev/null; then
        piper-say "$message" &
    fi
}

# Function to get current temperature
get_temperature() {
    if command -v smctemp &> /dev/null; then
        local temp_output
        # Get CPU temperature using smctemp -c
        temp_output=$(smctemp -c 2>/dev/null)
        # Extract just the number (e.g., "78.5" from output)
        local temp
        temp=$(echo "$temp_output" | grep -o '[0-9.]*' | head -1)
        echo "${temp:-0}"
    else
        echo "0"
    fi
}

# Function to get CPU usage for top processes and log them
get_top_cpu_processes() {
    local log_pids="${1:-false}"
    
    ps aux | sort -rk 3 | head -n $((MAX_PROCESSES + 1)) | tail -n "$MAX_PROCESSES" | \
    while read -r line; do
        local pid
        local cpu
        local cmd
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        cmd=$(echo "$line" | awk '{print $11}')
        
        echo "  $cmd (PID: $pid, ${cpu}% CPU)"
        
        # Log to PID file if requested
        if [ "$log_pids" = "true" ]; then
            log_problematic_pid "$pid" "$cmd" "High CPU" "${cpu}%"
        fi
    done
}

# Function to get RAM usage for top processes and log them
get_top_ram_processes() {
    local log_pids="${1:-false}"
    
    ps aux | sort -rk 4 | head -n $((MAX_PROCESSES + 1)) | tail -n "$MAX_PROCESSES" | \
    while read -r line; do
        local pid
        local mem
        local cmd
        pid=$(echo "$line" | awk '{print $2}')
        mem=$(echo "$line" | awk '{print $4}')
        cmd=$(echo "$line" | awk '{print $11}')
        
        echo "  $cmd (PID: $pid, ${mem}% RAM)"
        
        # Log to PID file if requested
        if [ "$log_pids" = "true" ]; then
            log_problematic_pid "$pid" "$cmd" "High RAM" "${mem}%"
        fi
    done
}

# Function to get overall CPU usage
get_overall_cpu() {
    local cpu_usage
    cpu_usage=$(top -l 2 -n 0 -F -R -s 1 | grep "CPU usage" | tail -1 | \
        awk '{print $3}' | sed 's/%//')
    echo "$cpu_usage"
}

# Function to get overall RAM usage
get_overall_ram() {
    local total_ram
    local page_size
    local mem_stats
    local pages_active
    local pages_wired
    local pages_compressed
    local used_ram
    local ram_percent
    
    total_ram=$(sysctl -n hw.memsize)
    page_size=$(pagesize)
    mem_stats=$(vm_stat)
    
    pages_active=$(echo "$mem_stats" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    pages_wired=$(echo "$mem_stats" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    pages_compressed=$(echo "$mem_stats" | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
    
    used_ram=$(( (pages_active + pages_wired + pages_compressed) * page_size ))
    ram_percent=$(awk "BEGIN {printf \"%.1f\", ($used_ram / $total_ram) * 100}")
    
    echo "$ram_percent"
}

# Function to check CPU usage of individual processes
check_cpu() {
    local current_time
    local time_since_last
    local found_high_cpu=false
    
    current_time=$(date +%s)
    time_since_last=$((current_time - LAST_CPU_ALERT_TIME))
    
    # Skip if we're in cooldown period
    if [ "$time_since_last" -lt "$ALERT_COOLDOWN" ]; then
        return
    fi
    
    # Check each process
    while IFS= read -r line; do
        local pid
        local cpu
        local cmd
        local cpu_int
        
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        cmd=$(echo "$line" | awk '{print $11}')
        cpu_int=${cpu%.*}
        
        # Check if this process exceeds threshold
        if [ "$cpu_int" -ge "$CPU_THRESHOLD" ]; then
            if [ "$found_high_cpu" = false ]; then
                echo -e "${YELLOW}⚠️  High CPU process(es) detected:${NC}"
                found_high_cpu=true
            fi
            
            echo "  $cmd (PID: $pid, ${cpu}% CPU)"
            log_problematic_pid "$pid" "$cmd" "High CPU" "${cpu}%"
        fi
    done < <(ps aux | tail -n +2 | sort -rk 3 | head -20)
    
    # Send alert if any high CPU processes were found
    if [ "$found_high_cpu" = true ]; then
        send_alert "High CPU processes detected above ${CPU_THRESHOLD} percent"
        LAST_CPU_ALERT_TIME=$current_time
    fi
}

# Function to check RAM usage of individual processes
check_ram() {
    local current_time
    local time_since_last
    local found_high_ram=false
    
    current_time=$(date +%s)
    time_since_last=$((current_time - LAST_RAM_ALERT_TIME))
    
    # Skip if we're in cooldown period
    if [ "$time_since_last" -lt "$ALERT_COOLDOWN" ]; then
        return
    fi
    
    # Check each process
    while IFS= read -r line; do
        local pid
        local mem
        local cmd
        local mem_int
        
        pid=$(echo "$line" | awk '{print $2}')
        mem=$(echo "$line" | awk '{print $4}')
        cmd=$(echo "$line" | awk '{print $11}')
        
        # Convert mem to integer for comparison
        mem_int=$(awk "BEGIN {printf \"%d\", $mem}")
        
        # Check if this process exceeds threshold
        if [ "$mem_int" -ge "$RAM_THRESHOLD" ]; then
            if [ "$found_high_ram" = false ]; then
                echo -e "${YELLOW}⚠️  High RAM process(es) detected:${NC}"
                found_high_ram=true
            fi
            
            echo "  $cmd (PID: $pid, ${mem}% RAM)"
            log_problematic_pid "$pid" "$cmd" "High RAM" "${mem}%"
        fi
    done < <(ps aux | tail -n +2 | sort -rk 4 | head -20)
    
    # Send alert if any high RAM processes were found
    if [ "$found_high_ram" = true ]; then
        send_alert "High RAM processes detected above ${RAM_THRESHOLD} percent"
        LAST_RAM_ALERT_TIME=$current_time
    fi
}

# Function to check temperature with sustained spike detection
check_temperature() {
    local temp
    local temp_int
    
    temp=$(get_temperature)
    temp_int=${temp%.*}
    
    if [ "$temp_int" -ge "$TEMP_THRESHOLD" ]; then
        TEMP_SPIKE_COUNTER=$((TEMP_SPIKE_COUNTER + 1))
        echo -e "${YELLOW}🌡️  Temperature spike detected: ${temp}°C (spike #${TEMP_SPIKE_COUNTER})${NC}"
        
        if [ "$TEMP_SPIKE_COUNTER" -ge "$TEMP_SPIKE_COUNT" ] && [ "$TEMP_ALERT_TRIGGERED" = false ]; then
            echo -e "${RED}🔥 Sustained temperature spikes detected!${NC}"
            echo "Top CPU processes (likely culprits):"
            get_top_cpu_processes "true"
            
            send_alert "Warning! Sustained temperature spikes detected. CPU at ${temp} degrees Celsius"
            TEMP_ALERT_TRIGGERED=true
        fi
    else
        # Reset counter if temperature drops below threshold
        if [ "$TEMP_SPIKE_COUNTER" -gt 0 ]; then
            echo -e "${GREEN}✓ Temperature normalized: ${temp}°C${NC}"
        fi
        TEMP_SPIKE_COUNTER=0
        TEMP_ALERT_TRIGGERED=false
    fi
}

# Function to display current status
display_status() {
    local cpu
    local ram
    local temp
    local top_cpu_proc
    local top_ram_proc
    
    cpu=$(get_overall_cpu)
    ram=$(get_overall_ram)
    temp=$(get_temperature)
    
    # Get top CPU process
    top_cpu_proc=$(ps aux | tail -n +2 | sort -rk 3 | head -1 | awk '{printf "%s (%.1f%%)", $11, $3}')
    # Get top RAM process
    top_ram_proc=$(ps aux | tail -n +2 | sort -rk 4 | head -1 | awk '{printf "%s (%.1f%%)", $11, $4}')
    
    clear
    echo "==========================================="
    echo "  System Monitor - $(date '+%H:%M:%S')"
    echo "==========================================="
    echo -e "Overall CPU: ${cpu}%  |  Overall RAM: ${ram}%"
    echo -e "Temperature: ${temp}°C (Threshold: ${TEMP_THRESHOLD}°C)"
    echo -e "Temp Spikes: ${TEMP_SPIKE_COUNTER}/${TEMP_SPIKE_COUNT}"
    echo "-------------------------------------------"
    echo -e "Monitoring individual processes:"
    echo -e "  CPU Threshold: ${CPU_THRESHOLD}% per process"
    echo -e "  RAM Threshold: ${RAM_THRESHOLD}% per process"
    echo "-------------------------------------------"
    echo -e "Top CPU: $top_cpu_proc"
    echo -e "Top RAM: $top_ram_proc"
    echo "==========================================="
    echo "PID Log: $PID_LOG_FILE"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo ""
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${GREEN}Monitoring stopped.${NC}"
    echo "Log file: $LOG_FILE"
    echo "PID log: $PID_LOG_FILE"
    if command -v piper-say &> /dev/null; then
        piper-say "System monitoring stopped" &
    fi
    exit 0
}

# Main monitoring loop
main_monitor() {
    echo "System Monitor Starting..."
    echo "Log file: $LOG_FILE"
    echo "PID log: $PID_LOG_FILE"
    echo ""
    
    check_dependencies
    init_pid_log_dir
    
    # Set up trap for clean exit
    trap cleanup SIGINT SIGTERM
    
    if command -v piper-say &> /dev/null; then
        piper-say "System monitoring started" &
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Monitoring started" >> "$LOG_FILE"
    
    while true; do
        display_status
        check_cpu
        check_ram
        check_temperature
        sleep "$CHECK_INTERVAL"
    done
}

# Parse command line arguments
while getopts "dh" opt; do
    case $opt in
        d)
            DAEMON_KILL_MODE=true
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Run appropriate mode
if [ "$DAEMON_KILL_MODE" = true ]; then
    init_pid_log_dir
    kill_logged_processes
else
    main_monitor
fi
