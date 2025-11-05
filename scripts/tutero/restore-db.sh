#!/usr/bin/env bash
set -euo pipefail

# Neo4j Docker Database Restore Script
# Usage: ./restore-db.sh [--prod] [gsutil-url] [database] [container]
# Interactive mode (dev): ./restore-db.sh
# Interactive mode (prod): ./restore-db.sh --prod
# Direct mode: ./restore-db.sh gs://neo4j-backups-prod/resources/neo4j-2025-11-04T12-03-33.backup
# Example: ./restore-db.sh gs://neo4j-backups-dev/learning/admin-2023-04-17T03-55-38.backup admin

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default credentials
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-password}"

# Cache settings
CACHE_DIR="/tmp"
MAX_CACHE_FILES=5

# GCS bucket configuration
BUCKET_PREFIX="gs://"
DEV_BUCKET="neo4j-backups-dev"
PROD_BUCKET="neo4j-backups-prod"
PROD_CONTEXT="tutero"  # or mathgaps-56d5a

# Function to print colored messages
info() {
    echo -e "${GREEN}✓${NC} $*" >&2
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}!${NC} $*" >&2
}

heading() {
    echo -e "${CYAN}▸${NC} ${BLUE}$*${NC}" >&2
}

# Function to check if fzf is available
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        warn "fzf not found. Install it for better UI: brew install fzf"
        return 1
    fi
    return 0
}

# Function to set kubectl context for production
set_prod_context() {
    heading "Setting kubectl context to ${PROD_CONTEXT}..."
    
    if kubectl config use-context "$PROD_CONTEXT" &>/dev/null; then
        info "Switched to context: ${PROD_CONTEXT}"
    else
        warn "Failed to switch context to ${PROD_CONTEXT}, continuing anyway..."
    fi
}

# Function to list backups in a bucket, sorted by date descending
list_backups() {
    local bucket="$1"
    local path_filter="${2:-}"
    
    heading "Fetching backups from ${bucket}..."
    
    local search_path="${BUCKET_PREFIX}${bucket}/"
    if [[ -n "$path_filter" ]]; then
        search_path="${search_path}${path_filter}/"
    fi
    
    # List all .backup files with their metadata
    local backups
    backups=$(gsutil ls -l "${search_path}**/*.backup" 2>/dev/null || echo "")
    
    if [[ -z "$backups" ]]; then
        error "No backups found in ${search_path}"
        return 1
    fi
    
    # Parse and format backup information
    # Format: timestamp|size|url|filename|date_display
    echo "$backups" | grep -v "^TOTAL:" | grep "\.backup$" | while read -r size datetime url; do
        if [[ -n "$url" && "$url" =~ \.backup$ ]]; then
            local filename
            filename=$(basename "$url")
            
            # Extract timestamp from filename (e.g., neo4j-2025-11-04T12-03-33.backup)
            local timestamp=""
            if [[ "$filename" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}) ]]; then
                timestamp="${BASH_REMATCH[1]}"
                # Convert to sortable format (YYYY-MM-DD HH:MM:SS)
                timestamp=$(echo "$timestamp" | sed 's/T/ /' | tr '-' ':' | sed 's/:/-/1' | sed 's/:/-/1')
            else
                # Use datetime from gsutil (e.g., 2023-04-12T17:01:55Z)
                timestamp=$(echo "$datetime" | sed 's/T/ /' | sed 's/Z$//')
            fi
            
            # Format size for display
            local size_display="$size"
            if [[ "$size" =~ ^[0-9]+$ ]]; then
                size_display=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "$size")
            fi
            
            # Get relative path
            local rel_path
            rel_path=$(echo "$url" | sed "s|${BUCKET_PREFIX}${bucket}/||")
            
            # Format datetime for display
            local date_display
            date_display=$(echo "$datetime" | sed 's/T/ /' | sed 's/Z$//')
            
            echo "${timestamp}|${size_display}|${url}|${filename}|${date_display}|${rel_path}"
        fi
    done | sort -t'|' -k1 -r
}

# Function to select backup interactively
select_backup() {
    local bucket="$1"
    local path_filter="${2:-}"
    
    local backups
    backups=$(list_backups "$bucket" "$path_filter") || return 1
    
    if check_fzf; then
        local selected
        selected=$(echo "$backups" | awk -F'|' '{printf "%-25s  %-10s  %s\n", $4, $2, $6}' | fzf \
            --height 60% \
            --reverse \
            --border \
            --prompt="Select backup: " \
            --header="Available Backups (sorted by date, newest first)" \
            --preview="echo {} | awk '{print \$1}' | xargs -I {} echo 'Filename: {}'" \
            --preview-window=up:3 \
            --bind 'ctrl-/:toggle-preview')
        
        if [[ -z "$selected" ]]; then
            error "No backup selected"
            return 1
        fi
        
        # Extract filename and find corresponding URL
        local selected_filename
        selected_filename=$(echo "$selected" | awk '{print $1}')
        local url
        url=$(echo "$backups" | grep "|${selected_filename}|" | cut -d'|' -f3)
        
        echo "$url"
    else
        # Fallback to simple selection
        heading "Available backups:"
        echo "$backups" | awk -F'|' '{printf "%s  %-10s  %s\n", $4, $2, $6}' | nl -w2 -s'. ' >&2
        echo -n "Select backup number: " >&2
        read -r selection
        echo "$backups" | sed -n "${selection}p" | cut -d'|' -f3
    fi
}

# Function to select subdirectory/path within bucket
select_path() {
    local bucket="$1"
    
    heading "Fetching subdirectories in ${bucket}..."
    
    local paths
    paths=$(gsutil ls "${BUCKET_PREFIX}${bucket}/" | grep '/$' | sed "s|${BUCKET_PREFIX}${bucket}/||" | sed 's|/$||' || echo "")
    
    if [[ -z "$paths" ]]; then
        warn "No subdirectories found, searching root of bucket"
        echo ""
        return 0
    fi
    
    # Add option for root directory
    paths="(root directory)
$paths"
    
    if check_fzf; then
        local selected
        selected=$(echo "$paths" | fzf \
            --height 40% \
            --reverse \
            --border \
            --prompt="Select path: " \
            --header="Select subdirectory (or root)" \
            --preview-window=hidden)
        
        if [[ -z "$selected" || "$selected" == "(root directory)" ]]; then
            echo ""
        else
            echo "$selected"
        fi
    else
        echo "$paths" | nl -w2 -s'. ' >&2
        echo -n "Select path number (1 for root): " >&2
        read -r selection
        local path
        path=$(echo "$paths" | sed -n "${selection}p")
        if [[ "$path" == "(root directory)" ]]; then
            echo ""
        else
            echo "$path"
        fi
    fi
}

# Function to interactive mode
interactive_mode() {
    local is_prod="$1"
    local bucket="$DEV_BUCKET"
    local env_label="Development"
    
    if [[ "$is_prod" == "true" ]]; then
        bucket="$PROD_BUCKET"
        env_label="Production"
        set_prod_context
    fi
    
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}" >&2
    echo -e "${MAGENTA}║  Neo4j Backup Restore - Interactive   ║${NC}" >&2
    echo -e "${MAGENTA}║  Environment: ${env_label}$(printf '%*s' $((24 - ${#env_label})) '')║${NC}" >&2
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}" >&2
    echo "" >&2
    
    info "Using bucket: ${bucket}"
    echo "" >&2
    
    # Step 1: Select path within bucket
    local path_filter
    path_filter=$(select_path "$bucket") || return 1
    if [[ -n "$path_filter" ]]; then
        info "Selected path: ${path_filter}"
    else
        info "Selected path: (root)"
    fi
    echo "" >&2
    
    # Step 2: Select backup
    local url
    url=$(select_backup "$bucket" "$path_filter") || return 1
    info "Selected backup: ${url}"
    echo "" >&2
    
    echo "$url"
}

# Function to validate gsutil URL
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^gs:// ]]; then
        error "Invalid URL: must start with gs://"
        return 1
    fi
    if [[ ! "$url" =~ \.backup$ ]]; then
        error "Invalid URL: must end with .backup"
        return 1
    fi
}

# Function to extract filename from URL
extract_filename() {
    local url="$1"
    basename "$url"
}

# Function to determine environment from URL (dev/prod)
detect_environment() {
    local url="$1"
    if [[ "$url" =~ neo4j-backups-prod ]]; then
        echo "prod"
    elif [[ "$url" =~ neo4j-backups-dev ]]; then
        echo "dev"
    else
        echo "unknown"
    fi
}

# Function to infer database name from filename
infer_database() {
    local filename="$1"
    if [[ "$filename" =~ ^admin- ]]; then
        echo "admin"
    elif [[ "$filename" =~ ^neo4j- ]]; then
        echo "neo4j"
    else
        error "Cannot infer database from filename: $filename"
        error "Filename must start with 'neo4j-' or 'admin-'"
        return 1
    fi
}

# Function to validate database name
validate_database() {
    local db="$1"
    if [[ "$db" != "neo4j" && "$db" != "admin" ]]; then
        error "Invalid database name: $db (must be 'neo4j' or 'admin')"
        return 1
    fi
}

# Function to list running Docker containers
list_containers() {
    echo -e "${BLUE}Available running containers:${NC}" >&2
    docker ps --format "  • {{.Names}} ({{.Image}})" >&2
}

# Function to get cache file path
get_cache_path() {
    local filename="$1"
    local env="$2"
    
    # Add environment suffix if prod
    if [[ "$env" == "prod" ]]; then
        echo "${CACHE_DIR}/${filename%.backup}.prod.backup"
    else
        echo "${CACHE_DIR}/${filename}"
    fi
}

# Function to check if backup exists in cache
check_cache() {
    local cache_path="$1"
    
    if [[ -f "$cache_path" ]]; then
        local size
        size=$(du -h "$cache_path" | cut -f1)
        info "Found cached backup: ${cache_path} (${size})"
        return 0
    fi
    return 1
}

# Function to manage cache (keep only last N files)
manage_cache() {
    local pattern="$1"
    
    # Find all backup files matching the pattern and sort by modification time (newest first)
    # Using stat for cross-platform compatibility
    local cache_files
    mapfile -t cache_files < <(
        find "$CACHE_DIR" -maxdepth 1 -name "${pattern}" -type f 2>/dev/null | while read -r file; do
            # macOS uses stat -f %m, Linux uses stat -c %Y
            if stat -f %m "$file" &>/dev/null; then
                echo "$(stat -f %m "$file") $file"
            else
                echo "$(stat -c %Y "$file") $file"
            fi
        done | sort -rn | cut -d' ' -f2-
    )
    
    # If we have more than MAX_CACHE_FILES, delete the oldest ones
    if [[ ${#cache_files[@]} -gt $MAX_CACHE_FILES ]]; then
        local files_to_delete=("${cache_files[@]:$MAX_CACHE_FILES}")
        for file in "${files_to_delete[@]}"; do
            warn "Removing old cached backup: $(basename "$file")"
            rm -f "$file"
        done
    fi
}

# Function to check if Docker container exists and is running
check_container() {
    local container="$1"
    
    # Check if any containers are running
    if ! docker ps -q &> /dev/null; then
        error "Docker is not running or no containers are available"
        return 1
    fi
    
    # Check if specific container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        error "Container '${container}' is not running"
        echo "" >&2
        list_containers
        return 1
    fi
    
    info "Container '${container}' is running"
}

# Function to download backup
download_backup() {
    local url="$1"
    local filename="$2"
    local env="$3"
    local output_path
    output_path=$(get_cache_path "$filename" "$env")
    
    # Check if backup exists in cache
    if check_cache "$output_path"; then
        echo "$output_path"
        return 0
    fi
    
    # Download backup
    info "Downloading backup to ${output_path}..."
    if gsutil cp "$url" "$output_path"; then
        local size
        size=$(du -h "$output_path" | cut -f1)
        info "Download complete (${size})"
        
        # Manage cache to keep only last N files
        manage_cache "*neo4j-*.backup" || true
        manage_cache "*neo4j-*.prod.backup" || true
        manage_cache "*admin-*.backup" || true
        manage_cache "*admin-*.prod.backup" || true
        
        echo "$output_path"
    else
        error "Failed to download backup"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_path="$1"
    local database="$2"
    local container="$3"
    local backup_filename
    backup_filename=$(basename "$backup_path")
    local container_backup_name="${backup_filename%.prod.backup}.backup"
    
    info "Copying backup to container..."
    docker cp "$backup_path" "${container}:/var/lib/neo4j/import/${container_backup_name}"
    
    info "Stopping database '${database}'..."
    docker exec "$container" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system "STOP DATABASE ${database}"
    
    info "Restoring database '${database}' from backup..."
    docker exec "$container" neo4j-admin database restore \
        --overwrite-destination=true \
        --from-path="/var/lib/neo4j/import/${container_backup_name}" \
        "$database"
    
    info "Starting database '${database}'..."
    docker exec "$container" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system "START DATABASE ${database}"
    
    info "Executing metadata restoration..."
    docker exec "$container" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d "$database" \
        -f "/data/scripts/${database}/restore_metadata.cypher" \
        --param "database => \"${database}\""
    
    info "Cleaning up container backup..."
    docker exec "$container" rm "/var/lib/neo4j/import/${container_backup_name}"
    
    info "Backup preserved at: ${backup_path}"
}

# Main script
main() {
    local url=""
    local database=""
    local container="resources-db"
    local is_prod="false"
    
    # Check for --prod flag
    if [[ "${1:-}" == "--prod" ]]; then
        is_prod="true"
        shift
    fi
    
    # Check if URL is provided (direct mode) or start interactive mode
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        url=$(interactive_mode "$is_prod") || exit 1
    else
        # Direct mode with arguments
        url="$1"
        database="${2:-}"
        container="${3:-resources-db}"
        
        # If using prod bucket in direct mode, set context
        if [[ "$url" =~ neo4j-backups-prod ]]; then
            set_prod_context
        fi
    fi
    
    # Validate URL
    validate_url "$url" || exit 1
    
    # Extract filename and environment
    local filename
    filename=$(extract_filename "$url")
    local env
    env=$(detect_environment "$url")
    
    info "Backup file: ${filename}"
    info "Environment: ${env}"
    
    # Determine database name
    if [[ -z "$database" ]]; then
        info "Database not specified, inferring from filename..."
        database=$(infer_database "$filename") || exit 1
        info "Inferred database: ${database}"
    else
        validate_database "$database" || exit 1
        info "Target database: ${database}"
    fi
    
    # Show container info
    info "Target container: ${container}"
    
    # Check container
    check_container "$container" || exit 1
    
    # Download backup
    local backup_path
    backup_path=$(download_backup "$url" "$filename" "$env") || exit 1
    
    # Restore database
    restore_database "$backup_path" "$database" "$container" || exit 1
    
    echo "" >&2
    info "Database '${database}' restored successfully in container '${container}'!"
    info "Backup saved at: ${backup_path}"
    
    # Audio feedback if piper-say is available
    if command -v piper-say &> /dev/null; then
        piper-say "Database ${database} restored successfully"
    fi
}

main "$@"
