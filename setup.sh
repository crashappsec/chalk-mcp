#!/usr/bin/env bash
set -euo pipefail

SETUP_REPO="${CHALK_MCP_SETUP_REPO:-crashappsec/chalk-mcp}"
SETUP_BRANCH="${CHALK_MCP_SETUP_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/$SETUP_REPO/$SETUP_BRANCH"
SERVER_NAME="chalk"
FORCE=false
LOCAL=false
TESTING=false
CHALK_IMAGE="ghcr.io/crashappsec/co/chalk-mcp-server"
CONFIG_DIR="$HOME/.config/chalk-mcp"
TOTAL_STEPS=4

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes|--force)
      FORCE=true
      shift
      ;;
    --local)
      LOCAL=true
      shift
      ;;
    --testing)
      TESTING=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -y, --yes, --force  Skip confirmation prompts, wipe existing data"
      echo "  --local             Rebuild and use the local image"
      echo "  --testing           Point chalk at the test environment (internal only)"
      echo "  -h, --help          Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

OS="$(uname -s)"

# Source shared library
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/setup-lib.sh" ]]; then
  # shellcheck source=setup-lib.sh
  source "$SCRIPT_DIR/setup-lib.sh"
else
  SETUP_LIB=$(mktemp)
  curl -fsSL "$RAW_BASE/setup-lib.sh" -o "$SETUP_LIB"
  source "$SETUP_LIB"
  rm -f "$SETUP_LIB"
fi

# ============================================================================
# Main Script
# ============================================================================

print_header

# Print version for debugging (only available for local/dev installs)
SETUP_VERSION=""
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.git" ]]; then
  SETUP_VERSION=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || true)
  [[ -n "$SETUP_VERSION" ]] && info "Version: $SETUP_VERSION"
fi

# Step 1: Check prerequisites
step 1 "Checking prerequisites..."

# Check Docker / MCP availability
if [[ "$OS" == "Linux" ]]; then
  if command -v docker &> /dev/null; then
    ok "Docker"
  else
    err "Docker not found"
    echo ""
    echo "      Install Docker Engine: https://docs.docker.com/engine/install/"
    exit 1
  fi
else
  if docker mcp version &> /dev/null; then
    ok "Docker MCP Toolkit"
  else
    err "Docker MCP Toolkit not available"
    echo ""
    echo "      Required: Docker Desktop 4.40+ with MCP Toolkit"
    echo "      Update at: https://www.docker.com/products/docker-desktop/"
    exit 1
  fi
fi

if [[ "$OS" == "Linux" ]]; then
  if docker mcp version &> /dev/null; then
    ok "Docker MCP Gateway plugin"
  else
    info "Docker MCP Gateway plugin not found. Installing..."

    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)        ARCH_SUFFIX="amd64" ;;
      aarch64|arm64) ARCH_SUFFIX="arm64" ;;
      *)
        err "Unsupported architecture: $ARCH"
        echo ""
        echo "      Check https://github.com/docker/mcp-gateway/releases for available binaries."
        exit 1
        ;;
    esac

    MCP_GW_REPO="docker/mcp-gateway"
    VERSION=$(curl -s "https://api.github.com/repos/$MCP_GW_REPO/releases/latest" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [[ -z "$VERSION" ]]; then
      err "Could not determine latest docker-mcp version"
      echo ""
      echo "      Install manually from: https://github.com/$MCP_GW_REPO/releases"
      exit 1
    fi

    DOWNLOAD_URL="https://github.com/$MCP_GW_REPO/releases/download/$VERSION/docker-mcp-linux-${ARCH_SUFFIX}.tar.gz"
    info "Downloading docker-mcp $VERSION (linux/${ARCH_SUFFIX})..."

    mkdir -p ~/.docker/cli-plugins
    curl -sL "$DOWNLOAD_URL" -o /tmp/docker-mcp.tar.gz
    tar xzf /tmp/docker-mcp.tar.gz -C ~/.docker/cli-plugins
    chmod +x ~/.docker/cli-plugins/docker-mcp
    rm -f /tmp/docker-mcp.tar.gz

    if docker mcp version &> /dev/null; then
      ok "Docker MCP Gateway plugin installed"
    else
      err "Installation failed"
      echo ""
      echo "      Install manually from: https://github.com/$MCP_GW_REPO/releases"
      exit 1
    fi
  fi

  export DOCKER_MCP_IN_CONTAINER=1
fi

# Step 2: Check for existing installation
step 2 "Checking for existing installation..."

detect_existing_installation

if $FORCE; then
  WIPE_CONFIG=true
  WIPE_VOLUME=true
  if $CONFIG_EXISTS || $VOLUME_EXISTS; then
    warn "Existing installation detected"
  else
    info "Force mode enabled - wiping any previous state"
  fi
elif $CONFIG_EXISTS || $VOLUME_EXISTS; then
  warn "Existing installation detected"
  prompt_existing_installation
else
  ok "Fresh install"
fi

# Apply wipe decisions
if $WIPE_CONFIG; then
  rm -rf "$CONFIG_DIR"
fi
rm -rf /tmp/chalk-mcp

# Step 3: Client selection
step 3 "Select MCP clients to connect"

prompt_client_selection

# Step 4: Install
step 4 "Installing..."

# Cleanup previous installation (silent)
cleanup_catalog
cleanup_old_containers
cleanup_clickhouse

# Prepare image
if $LOCAL; then
  info "Rebuilding local image (--local flag set)..."
  docker build -t chalk-mcp-server:latest -t "$CHALK_IMAGE:latest" .
else
  info "Pulling latest image..."
  docker pull "$CHALK_IMAGE:latest" >/dev/null 2>&1 || true
fi
ok "Image ready"

# Download and import catalog
if [[ "$OS" == "Linux" ]]; then
  CATALOG_NAME="chalk-catalog-linux.yaml"
  CATALOG_FILE="/tmp/chalk-catalog-linux.yaml"
else
  CATALOG_NAME="chalk-catalog.yaml"
  CATALOG_FILE="/tmp/chalk-catalog.yaml"
fi

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$CATALOG_NAME" ]]; then
  info "Using local catalog"
  cp "$SCRIPT_DIR/$CATALOG_NAME" "$CATALOG_FILE"
else
  info "Downloading catalog..."
  curl -fsSL "$RAW_BASE/$CATALOG_NAME" -o "$CATALOG_FILE" || {
    err "Could not download catalog"
    exit 1
  }
fi

CHALK_CONFIG_DIR="$HOME/.config/chalk-mcp"
mkdir -p "$CHALK_CONFIG_DIR"
CHALK_TESTING=""
if $TESTING; then
  CHALK_TESTING="1"
fi

if [[ "$OS" == "Linux" ]]; then
  sed -i "s|__HOME__|$HOME|g" "$CATALOG_FILE"
  sed -i "s|__CONFIG_DIR__|$CHALK_CONFIG_DIR|g" "$CATALOG_FILE"
  sed -i "s|__CHALK_TESTING_VALUE__|$CHALK_TESTING|g" "$CATALOG_FILE"
else
  AUTH0_CLIENT_ID="${CHALK_AUTH0_CLIENT_ID:-}"
  sed -e "s|__CONFIG_DIR__|$CHALK_CONFIG_DIR|g" \
      -e "s|__AUTH0_CLIENT_ID__|$AUTH0_CLIENT_ID|g" \
      -e "s|__CHALK_TESTING_VALUE__|$CHALK_TESTING|g" \
      "$CATALOG_FILE" > "$CATALOG_FILE.tmp" \
    && mv "$CATALOG_FILE.tmp" "$CATALOG_FILE"
fi

docker mcp catalog import "$CATALOG_FILE" >/dev/null 2>&1 || true
rm -f "$CATALOG_FILE"
ok "Imported catalog"

# Enable server
if docker mcp server enable "$SERVER_NAME" 2>&1; then
  ok "Enabled server"
else
  warn "Failed to enable server. Try: docker mcp server enable chalk"
fi

# Connect selected clients
connect_selected_clients
clients_str=$(printf "%s, " "${SELECTED_CLIENTS[@]}")
clients_str="${clients_str%, }"
if $REUSING_CLIENTS; then
  ok "Re-connected: $clients_str"
else
  ok "Connected: $clients_str"
fi

# Success!
print_success_banner
print_next_steps
