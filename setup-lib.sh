#!/usr/bin/env bash
# Shared library for Chalk MCP Server setup scripts
# Sourced by setup.sh

# ============================================================================
# Colors & Formatting
# ============================================================================

setup_colors() {
  if [[ -t 1 ]] && [[ -n "${TERM:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
  else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    DIM=''
    NC=''
  fi
}

# ============================================================================
# Logging Helpers
# ============================================================================

info()  { echo -e "${BLUE}▸${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*"; }
step()  { echo -e "\n${BOLD}[$1/$TOTAL_STEPS]${NC} $2"; }

# ============================================================================
# Interactive Detection
# ============================================================================

is_interactive() {
  [[ -t 0 || -t 2 ]] && [[ -e /dev/tty ]] && ! $FORCE
}

# ============================================================================
# Header
# ============================================================================

print_header() {
  echo ""
  echo "┌────────────────────────────────────────────────────────────────┐"
  echo "│                     Chalk MCP Server Setup                     │"
  echo "└────────────────────────────────────────────────────────────────┘"
  echo ""
}

# ============================================================================
# Existing Installation Detection
# ============================================================================

detect_existing_installation() {
  CONFIG_EXISTS=false
  VOLUME_EXISTS=false
  WIPE_CONFIG=false
  WIPE_VOLUME=false

  # Treat any non-empty config dir as stateful. This covers both legacy flat
  # files and the current per-account layout under accounts/.
  if [[ -d "$CONFIG_DIR" ]]; then
    if find "$CONFIG_DIR" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
      CONFIG_EXISTS=true
    fi
  fi

  # Check volume
  if [[ -n "$(docker volume ls -q --filter name=chalk-mcp-data 2>/dev/null)" ]]; then
    VOLUME_EXISTS=true
  fi
}

prompt_existing_installation() {
  if ! $CONFIG_EXISTS && ! $VOLUME_EXISTS; then
    return 0  # Nothing to prompt about
  fi

  if ! is_interactive; then
    if $FORCE; then
      WIPE_CONFIG=true
      WIPE_VOLUME=true
      return 0
    fi
    err "Existing installation detected. Use --force to overwrite or run interactively."
    exit 1
  fi

  echo ""
  echo "      ┌──────────────────────────────────────────────────────────┐"
  if $CONFIG_EXISTS; then
    echo "      │ Config: ~/.config/chalk-mcp (auth, settings)            │"
  fi
  if $VOLUME_EXISTS; then
    echo "      │ Volume: chalk-mcp-data (stored reports)                 │"
  fi
  echo "      └──────────────────────────────────────────────────────────┘"
  echo ""
  echo "      How would you like to proceed?"
  echo ""
  echo "      [K] Keep everything - update server only (Recommended)"
  echo "      [W] Wipe everything - fresh install"
  echo "      [A] Abort"
  echo ""
  read -p "      Choice [K/w/a]: " -n 1 -r < /dev/tty
  echo ""

  case "$REPLY" in
    [Ww])
      WIPE_CONFIG=true
      WIPE_VOLUME=true
      ;;
    [Aa])
      echo ""
      info "Aborted."
      exit 1
      ;;
    *)
      # Default: keep everything
      WIPE_CONFIG=false
      WIPE_VOLUME=false
      ;;
  esac
}

# ============================================================================
# Client Selection
# ============================================================================

# Known MCP clients
KNOWN_CLIENTS=("claude-code" "cursor" "claude-desktop" "vscode" "kiro" "gemini")

get_client_status() {
  local client="$1"
  # Parse docker mcp client ls output (strip ANSI codes first)
  # Format: " ● client-name: connected" or " ● client-name: disconnected" or " ● client-name: no mcp configured"
  local output line
  output=$(docker mcp client ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || true)
  line=$(echo "$output" | grep -E "● $client:" || true)
  if [[ -z "$line" ]]; then
    echo "not-found"
  elif echo "$line" | grep -q ": connected"; then
    echo "connected"
  elif echo "$line" | grep -q ": disconnected"; then
    echo "disconnected"
  else
    echo "not-configured"
  fi
}

get_connected_clients() {
  # Returns list of currently connected clients
  local connected=()
  for client in "${KNOWN_CLIENTS[@]}"; do
    if [[ "$(get_client_status "$client")" == "connected" ]]; then
      connected+=("$client")
    fi
  done
  echo "${connected[@]+"${connected[@]}"}"
}

prompt_client_selection() {
  SELECTED_CLIENTS=()
  REUSING_CLIENTS=false

  # Check for already connected clients
  local connected
  connected=$(get_connected_clients)

  if [[ -n "$connected" ]]; then
    # Auto-select previously connected clients
    # shellcheck disable=SC2206
    SELECTED_CLIENTS=($connected)
    REUSING_CLIENTS=true

    local clients_str
    clients_str=$(printf "%s, " "${SELECTED_CLIENTS[@]}")
    clients_str="${clients_str%, }"
    info "Re-connecting previously connected clients: $clients_str"
    return 0
  fi

  # No clients connected - prompt user or use defaults
  if ! is_interactive; then
    local already
    already=$(get_connected_clients)
    if [[ -n "$already" ]]; then
      # shellcheck disable=SC2206
      SELECTED_CLIENTS=($already)
    else
      SELECTED_CLIENTS=("claude-code")
    fi
    return 0
  fi

  echo ""
  echo "      Available clients:"
  echo ""

  local i=1
  for client in "${KNOWN_CLIENTS[@]}"; do
    local status
    status=$(get_client_status "$client")
    local mark=" "
    # Pre-select claude-code
    [[ "$client" == "claude-code" ]] && mark="x"
    printf "      [%s] %d. %-16s (currently: %s)\n" "$mark" "$i" "$client" "$status"
    ((i++))
  done

  echo ""
  read -p "      Toggle with numbers (space-separated), Enter for default [1]: " -r selection < /dev/tty
  echo ""

  # Parse selection
  if [[ -z "$selection" ]]; then
    SELECTED_CLIENTS=("claude-code")
  else
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#KNOWN_CLIENTS[@]} )); then
        SELECTED_CLIENTS+=("${KNOWN_CLIENTS[$((num-1))]}")
      fi
    done
    # Fallback to claude-code if nothing valid selected
    [[ ${#SELECTED_CLIENTS[@]} -eq 0 ]] && SELECTED_CLIENTS=("claude-code")
  fi
}

disconnect_all_clients() {
  for client in "${KNOWN_CLIENTS[@]}"; do
    docker mcp client disconnect "$client" >/dev/null 2>&1 || true
  done
}

connect_selected_clients() {
  disconnect_all_clients
  for client in "${SELECTED_CLIENTS[@]}"; do
    docker mcp client connect "$client" >/dev/null 2>&1 || true
    docker mcp client connect "$client" --global >/dev/null 2>&1 || true
  done
}

# ============================================================================
# Container Cleanup
# ============================================================================

cleanup_old_containers() {
  # Stop and remove any running chalk-mcp-server containers
  for cid in $(docker ps -q --filter "ancestor=$CHALK_IMAGE" 2>/dev/null); do
    docker stop "$cid" >/dev/null 2>&1 || true
    docker rm "$cid" >/dev/null 2>&1 || true
  done
  # Also catch containers by name, excluding clickhouse (cleaned up separately)
  for cid in $(docker ps -aq --filter "name=chalk-mcp" 2>/dev/null); do
    local cname
    cname=$(docker inspect --format '{{.Name}}' "$cid" 2>/dev/null || true)
    [[ "$cname" == "/chalk-mcp-clickhouse" ]] && continue
    docker stop "$cid" >/dev/null 2>&1 || true
    docker rm "$cid" >/dev/null 2>&1 || true
  done
}

cleanup_clickhouse() {
  docker stop chalk-mcp-clickhouse >/dev/null 2>&1 || true
  docker rm chalk-mcp-clickhouse >/dev/null 2>&1 || true
  if $WIPE_VOLUME; then
    docker volume rm chalk-mcp-data >/dev/null 2>&1 || true
  fi
}

cleanup_catalog() {
  docker mcp server disable "$SERVER_NAME" >/dev/null 2>&1 || true
  docker mcp catalog rm chalk-catalog >/dev/null 2>&1 || true
  docker mcp catalog rm chalk-test >/dev/null 2>&1 || true
  docker mcp catalog rm "$SERVER_NAME" >/dev/null 2>&1 || true
}

# ============================================================================
# Success Banner & Next Steps
# ============================================================================

print_success_banner() {
  echo ""
  cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║      ██████╗██╗  ██╗ █████╗ ██╗     ██╗  ██╗                   ║
║     ██╔════╝██║  ██║██╔══██╗██║     ██║ ██╔╝                   ║
║     ██║     ███████║███████║██║     █████╔╝                    ║
║     ██║     ██╔══██║██╔══██║██║     ██╔═██╗                    ║
║     ╚██████╗██║  ██║██║  ██║███████╗██║  ██╗                   ║
║      ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                   ║
║                                                                ║
║               Setup Complete! Restart your client.             ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
}

print_next_steps() {
  # Build connected clients string
  local clients_str
  clients_str=$(printf "%s, " "${SELECTED_CLIENTS[@]}")
  clients_str="${clients_str%, }"  # Remove trailing ", "

  cat << EOF

┌────────────────────────────────────────────────────────────────┐
│                          Next Steps                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. Restart your MCP client ($clients_str)
│                                                                │
│  2. Choose your storage mode:                                  │
│     • "Configure chalk for local storage"                      │
│        Data stays on your machine                              │
│     • "Configure chalk for hosted storage"                     │
│        Hosted by Crash Override - enables heartbeat and        │
│        exec reports from deployed services                     │
│                                                                │
│  3. Try these prompts:                                         │
│                                                                │
│     Build & Push:                                              │
│       • "Build my Dockerfile with provenance"                  │
│       • "Push image with traceability"                         │
│                                                                │
│     Analyze:                                                   │
│       • "Run security analyzer on this repo"                   │
│       • "Detect tech stack"                                    │
│       • "Check for secrets"                                    │
│                                                                │
│     Inspect:                                                   │
│       • "Extract chalk mark from image"                        │
│       • "Scan all local images"                                │
│                                                                │
│     Query:                                                     │
│       • "Show my recent builds"                                │
│       • "Check health status"                                  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
EOF
}

# Initialize colors on source
setup_colors
