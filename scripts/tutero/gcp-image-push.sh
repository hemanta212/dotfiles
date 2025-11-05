#!/usr/bin/env bash
set -euo pipefail

# Docker Image Build & Push Script
# Usage: ./push.sh [image-name] [dockerfile-path]
# Example: ./push.sh learning-latex ./Dockerfile
# Interactive mode: ./push.sh

# ============================================================================
# CONFIGURATION - Modify these as needed
# ============================================================================

MAINTAINER="sharmahemanta.212@gmail.com"
TUTERO_REGISTRY="australia-southeast1-docker.pkg.dev/mathgaps-56d5a/registry"
GCP_PROJECT="mathgaps-56d5a"
GCP_LOCATION="australia-southeast1"
REPOSITORY_NAME="registry"
PLATFORM="linux/amd64"
MAX_VERSIONS_TO_SHOW=5

# ============================================================================
# COLORS & HELPERS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

check_fzf() {
  if ! command -v fzf &>/dev/null; then
    error "fzf not found. Install it: brew install fzf"
    exit 1
  fi
}

check_gcloud() {
  if ! command -v gcloud &>/dev/null; then
    error "gcloud not found. Install Google Cloud SDK"
    exit 1
  fi
}

check_docker() {
  if ! command -v docker &>/dev/null; then
    error "docker not found. Install Docker"
    exit 1
  fi

  if ! docker info &>/dev/null; then
    error "Docker daemon is not running"
    exit 1
  fi
}

# Set gcloud project context
set_gcloud_context() {
  heading "Setting gcloud project context..."

  local current_project
  current_project=$(gcloud config get-value project 2>/dev/null || echo "")

  if [[ "$current_project" != "$GCP_PROJECT" ]]; then
    info "Switching to project: ${GCP_PROJECT}"
    gcloud config set project "$GCP_PROJECT" &>/dev/null
  else
    info "Already using project: ${GCP_PROJECT}"
  fi
}

# Fetch description from image config blob (without pulling)
fetch_image_description() {
  local image_name="$1"  # e.g., "learning-latex"
  local tag="$2"         # e.g., "1.2.7"
  
  # Get access token
  local token
  token=$(gcloud auth print-access-token 2>/dev/null)
  
  # Get manifest to find config blob digest
  local manifest
  manifest=$(curl -s -L \
    -H "Authorization: Bearer $token" \
    "https://${GCP_LOCATION}-docker.pkg.dev/v2/${GCP_PROJECT}/${REPOSITORY_NAME}/${image_name}/manifests/${tag}" 2>/dev/null)
  
  # Extract config digest
  local config_digest
  config_digest=$(echo "$manifest" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('config', {}).get('digest', ''))" 2>/dev/null || echo "")
  
  if [[ -z "$config_digest" ]]; then
    echo ""
    return 0
  fi
  
  # Fetch config blob and extract description
  local description
  description=$(curl -s -L \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.docker.container.image.v1+json" \
    "https://${GCP_LOCATION}-docker.pkg.dev/v2/${GCP_PROJECT}/${REPOSITORY_NAME}/${image_name}/blobs/${config_digest}" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); labels=data.get('config', {}).get('Labels', {}); print(labels.get('description', labels.get('org.opencontainers.image.description', '')))" 2>/dev/null || echo "")
  
  echo "$description"
}

# Fetch existing image tags from Artifact Registry with descriptions
fetch_image_tags() {
  local image_name="$1"

  heading "Fetching existing versions for ${image_name}..."

  # List all tags for this image, sorted by version (newest first)
  local tags
  tags=$(gcloud artifacts docker tags list \
    "${TUTERO_REGISTRY}/${image_name}" \
    --format="value(tag)" 2>/dev/null | sort -V -r | head -n "$MAX_VERSIONS_TO_SHOW" || echo "")

  if [[ -z "$tags" ]]; then
    warn "No existing versions found for ${image_name}"
    echo ""
    return 0
  fi

  echo "$tags"
}

# Parse semantic version and increment patch version
increment_version() {
  local version="$1"

  # Extract major.minor.patch
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"

    # Increment patch
    patch=$((patch + 1))
    echo "${major}.${minor}.${patch}"
  elif [[ "$version" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    # Handle x.y format
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    echo "${major}.${minor}.1"
  else
    # Default version if parsing fails
    echo "1.0.0"
  fi
}

# Interactive version selection
select_version() {
  local image_name="$1"
  local existing_tags="$2"

  local suggested_version="1.0.0"

  if [[ -n "$existing_tags" ]]; then
    # Show existing versions immediately
    info "Recent versions:"
    
    # Create temp directory for descriptions
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Display versions immediately and fetch descriptions in parallel
    local tag_count=0
    while IFS= read -r tag; do
      if [[ -n "$tag" ]]; then
        tag_count=$((tag_count + 1))
        echo -e "  ${GREEN}•${NC} ${YELLOW}${tag}${NC} ${CYAN}(loading...)${NC}" >&2
        
        # Fetch description in background
        (
          desc=$(fetch_image_description "$image_name" "$tag")
          echo "$desc" > "${temp_dir}/${tag}.desc"
        ) &
      fi
    done <<< "$existing_tags"
    
    # Wait for all background jobs to complete
    wait
    
    # Clear the lines we just printed
    for ((i=0; i<tag_count+1; i++)); do
      echo -ne "\033[1A\033[2K" >&2  # Move up and clear line
    done
    
    # Re-display with descriptions
    info "Recent versions:"
    while IFS= read -r tag; do
      if [[ -n "$tag" ]]; then
        desc=""
        if [[ -f "${temp_dir}/${tag}.desc" ]]; then
          desc=$(cat "${temp_dir}/${tag}.desc")
        fi
        
        if [[ -n "$desc" ]]; then
          echo -e "  ${GREEN}•${NC} ${YELLOW}${tag}${NC} - ${desc}" >&2
        else
          echo -e "  ${GREEN}•${NC} ${YELLOW}${tag}${NC}" >&2
        fi
      fi
    done <<< "$existing_tags"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "" >&2

    # Get the latest version and suggest next
    local latest_version
    latest_version=$(echo "$existing_tags" | head -n1)
    suggested_version=$(increment_version "$latest_version")
  fi

  # Prompt for version
  echo -e "${CYAN}▸${NC} ${BLUE}Enter version [${suggested_version}]:${NC} " >&2
  read -r version

  # Use suggested version if empty
  if [[ -z "$version" ]]; then
    version="$suggested_version"
  fi

  # Validate version format
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    warn "Version should be in format x.y.z (e.g., 1.2.3)"
    echo -e "${CYAN}▸${NC} ${BLUE}Enter version [${suggested_version}]:${NC} " >&2
    read -r version
    if [[ -z "$version" ]]; then
      version="$suggested_version"
    fi
  fi

  echo "$version"
}

# Prompt for image description
prompt_description() {
  echo -e "${CYAN}▸${NC} ${BLUE}Enter image description (optional):${NC} " >&2
  read -r description
  echo "$description"
}

# Build Docker image with labels
build_image() {
  local image_name="$1"
  local version="$2"
  local dockerfile="$3"
  local description="$4"

  local full_tag="${TUTERO_REGISTRY}/${image_name}:${version}"

  heading "Building Docker image: ${full_tag}..."

  # Build command with labels
  local build_cmd="docker build"
  build_cmd+=" -f \"${dockerfile}\""
  build_cmd+=" --platform=${PLATFORM}"
  build_cmd+=" --label \"maintainer=${MAINTAINER}\""
  build_cmd+=" --label \"version=${version}\""

  if [[ -n "$description" ]]; then
    build_cmd+=" --label \"description=${description}\""
    build_cmd+=" --label \"org.opencontainers.image.description=${description}\""
  fi

  build_cmd+=" --label \"org.opencontainers.image.version=${version}\""
  build_cmd+=" --label \"org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
  build_cmd+=" -t \"${full_tag}\""
  build_cmd+=" ."

  info "Build command: ${build_cmd}"
  echo "" >&2

  # Execute build
  if eval "$build_cmd"; then
    info "Build successful!"
    echo "$full_tag"
    return 0
  else
    error "Build failed"
    return 1
  fi
}

# Push Docker image to registry
push_image() {
  local full_tag="$1"

  heading "Pushing image to registry: ${full_tag}..."

  if docker push "$full_tag"; then
    info "Push successful!"
    return 0
  else
    error "Push failed"
    return 1
  fi
}

# Attach description as README to Artifact Registry
attach_description() {
  local full_tag="$1"
  local description="$2"
  local version="$3"

  if [[ -z "$description" ]]; then
    return 0
  fi

  # Note: gcloud artifacts attachments is not available in SDK 486.0.0
  # The description is already embedded in Docker labels which can be viewed with:
  # docker inspect <image> or gcloud artifacts docker images describe <image>
  
  info "Description saved in image labels (use 'docker inspect' to view)"
  return 0
}

# Display summary
show_summary() {
  local image_name="$1"
  local version="$2"
  local description="$3"
  local full_tag="$4"

  echo "" >&2
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}" >&2
  echo -e "${MAGENTA}║                  Build & Push Complete                     ║${NC}" >&2
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}" >&2
  echo "" >&2
  info "Image: ${image_name}"
  info "Version: ${version}"
  if [[ -n "$description" ]]; then
    info "Description: ${description}"
    info "💡 View labels: docker inspect ${full_tag}"
  fi
  info "Full tag: ${full_tag}"
  info "Maintainer: ${MAINTAINER}"
  echo "" >&2
  info "View in Console: https://console.cloud.google.com/artifacts/docker/${GCP_PROJECT}/${GCP_LOCATION}/${REPOSITORY_NAME}/${image_name}?project=${GCP_PROJECT}"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
  local image_name="${1:-}"
  local dockerfile="${2:-}"

  # Check dependencies
  check_fzf
  check_gcloud
  check_docker

  # Banner
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}" >&2
  echo -e "${MAGENTA}║           Docker Image Build & Push to GCP                 ║${NC}" >&2
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}" >&2
  echo "" >&2

  # Prompt for image name if not provided
  if [[ -z "$image_name" ]]; then
    echo -e "${CYAN}▸${NC} ${BLUE}Enter image name (e.g., learning-latex):${NC} " >&2
    read -r image_name
  fi

  if [[ -z "$image_name" ]]; then
    error "Image name is required"
    exit 1
  fi

  info "Image name: ${image_name}"

  # Prompt for Dockerfile path if not provided
  if [[ -z "$dockerfile" ]]; then
    echo -e "${CYAN}▸${NC} ${BLUE}Enter Dockerfile path [./Dockerfile]:${NC} " >&2
    read -r dockerfile
    if [[ -z "$dockerfile" ]]; then
      dockerfile="./Dockerfile"
    fi
  fi

  # Validate Dockerfile exists
  if [[ ! -f "$dockerfile" ]]; then
    error "Dockerfile not found: ${dockerfile}"
    exit 1
  fi

  info "Dockerfile: ${dockerfile}"
  echo "" >&2

  # Set gcloud context
  set_gcloud_context
  echo "" >&2

  # Fetch existing tags
  local existing_tags
  existing_tags=$(fetch_image_tags "$image_name")
  echo "" >&2

  # Select version
  local version
  version=$(select_version "$image_name" "$existing_tags")
  info "Selected version: ${version}"
  echo "" >&2

  # Prompt for description
  local description
  description=$(prompt_description)
  if [[ -n "$description" ]]; then
    info "Description: ${description}"
  fi
  echo "" >&2

  # Build image
  local full_tag
  full_tag=$(build_image "$image_name" "$version" "$dockerfile" "$description") || exit 1
  echo "" >&2

  # Push image
  push_image "$full_tag" || exit 1
  echo "" >&2

  # Attach description to Artifact Registry
  attach_description "$full_tag" "$description" "$version"

  # Show summary
  show_summary "$image_name" "$version" "$description" "$full_tag"

  # Audio feedback if available
  if command -v piper-say &>/dev/null; then
    piper-say "Docker image ${image_name} version ${version} pushed successfully"
  fi
}

main "$@"
