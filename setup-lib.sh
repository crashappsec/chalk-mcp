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

# Check if a client application is installed on the system (independent of docker mcp)
is_client_installed() {
  local client="$1"
  case "$client" in
    claude-code)
      command -v claude &>/dev/null && return 0
      [[ -d "/Applications/Claude Code.app" ]] && return 0
      ;;
    cursor)
      command -v cursor &>/dev/null && return 0
      [[ -d "/Applications/Cursor.app" ]] && return 0
      [[ -f "$HOME/.local/share/applications/cursor.desktop" ]] && return 0
      ;;
    claude-desktop)
      [[ -d "/Applications/Claude.app" ]] && return 0
      [[ -f "$HOME/.local/share/applications/claude.desktop" ]] && return 0
      ;;
    vscode)
      command -v code &>/dev/null && return 0
      [[ -d "/Applications/Visual Studio Code.app" ]] && return 0
      ;;
    kiro)
      command -v kiro &>/dev/null && return 0
      [[ -d "/Applications/Kiro.app" ]] && return 0
      ;;
    gemini)
      command -v gemini &>/dev/null && return 0
      ;;
  esac
  return 1
}

get_client_status() {
  local client="$1"
  # Parse docker mcp client ls output (strip ANSI codes first)
  # Format: " ● client-name: connected" or " ● client-name: disconnected" or " ● client-name: no mcp configured"
  local output line
  output=$(docker mcp client ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || true)
  line=$(echo "$output" | grep -E "● $client:" || true)
  if [[ -z "$line" ]]; then
    if is_client_installed "$client"; then
      echo "installed"
    else
      echo "not-found"
    fi
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

  # Build list of installed clients (detected on system)
  local installed_clients=()
  for client in "${KNOWN_CLIENTS[@]}"; do
    if is_client_installed "$client"; then
      installed_clients+=("$client")
    fi
  done

  if [[ -n "$connected" ]]; then
    # Start with previously connected clients, add any installed but not yet connected
    # shellcheck disable=SC2206
    SELECTED_CLIENTS=($connected)
    for ic in "${installed_clients[@]+"${installed_clients[@]}"}"; do
      local already=false
      for sc in "${SELECTED_CLIENTS[@]}"; do
        [[ "$ic" == "$sc" ]] && already=true && break
      done
      $already || SELECTED_CLIENTS+=("$ic")
    done
    REUSING_CLIENTS=true

    local clients_str
    clients_str=$(printf "%s, " "${SELECTED_CLIENTS[@]}")
    clients_str="${clients_str%, }"
    info "Connecting clients: $clients_str"
    return 0
  fi

  # No clients connected - prompt user or use defaults
  if ! is_interactive; then
    if [[ ${#installed_clients[@]} -gt 0 ]]; then
      SELECTED_CLIENTS=("${installed_clients[@]}")
    else
      SELECTED_CLIENTS=("claude-code")
    fi
    return 0
  fi

  echo ""
  echo "      Available clients:"
  echo ""

  # Pre-select installed clients; fall back to claude-code if none detected
  local defaults=()
  if [[ ${#installed_clients[@]} -gt 0 ]]; then
    defaults=("${installed_clients[@]}")
  else
    defaults=("claude-code")
  fi

  local i=1
  for client in "${KNOWN_CLIENTS[@]}"; do
    local status
    status=$(get_client_status "$client")
    local mark=" "
    for d in "${defaults[@]}"; do
      [[ "$client" == "$d" ]] && mark="x" && break
    done
    printf "      [%s] %d. %-16s (currently: %s)\n" "$mark" "$i" "$client" "$status"
    ((i++))
  done

  # Build default numbers string for prompt
  local default_nums=()
  local j=1
  for client in "${KNOWN_CLIENTS[@]}"; do
    for d in "${defaults[@]}"; do
      [[ "$client" == "$d" ]] && default_nums+=("$j") && break
    done
    ((j++))
  done
  local default_str
  default_str=$(printf "%s " "${default_nums[@]}")
  default_str="${default_str% }"

  echo ""
  read -p "      Toggle with numbers (space-separated), Enter for default [$default_str]: " -r selection < /dev/tty
  echo ""

  # Parse selection
  if [[ -z "$selection" ]]; then
    SELECTED_CLIENTS=("${defaults[@]}")
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

# ============================================================================
# Bug Report
# ============================================================================

# Same endpoint the MCP server uses (pkg/bugreport/sender.go)
# CHALKAPI_URL validated at use time (run_bug_report), not at source time
BUG_REPORT_API=""
BUG_REPORT_QUEUE_DIR="${CONFIG_DIR:-$HOME/.config/chalk-mcp}/bug-reports"

extract_report_id() {
  echo "$1" | grep -o '"id": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}

queue_bug_report() {
  local json_payload="$1"
  local report_id queue_file tmp_file

  report_id=$(extract_report_id "$json_payload")
  if [[ -z "$report_id" ]]; then
    err "Failed to extract report ID"
    return 1
  fi

  mkdir -p "$BUG_REPORT_QUEUE_DIR" || return 1

  queue_file="$BUG_REPORT_QUEUE_DIR/$report_id.json"
  tmp_file="$queue_file.tmp.$$"
  printf '%s\n' "$json_payload" > "$tmp_file"
  mv "$tmp_file" "$queue_file"

  echo "$queue_file"
}

collect_diagnostics_json() {
  local error_message="${1:-}"
  local description="${2:-}"

  local host_os host_arch docker_version docker_server
  local container_runtime has_docker has_network

  host_os="$(uname -s)"
  host_arch="$(uname -m)"

  docker_version=$(docker version --format '{{.Client.Version}}' 2>/dev/null || echo "")
  docker_server=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "")

  has_docker=false
  command -v docker &>/dev/null && has_docker=true

  has_network=false
  if curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://crashoverride.com 2>/dev/null | grep -q "^[23]"; then
    has_network=true
  fi

  container_runtime=$(docker info --format '{{.OperatingSystem}}' 2>/dev/null || echo "unknown")

  local chalk_version
  chalk_version=$(/usr/local/bin/chalk --version 2>/dev/null || echo "unknown")

  # Build logs: MCP state + container logs + chalk logs
  local logs=""

  # Docker MCP toolkit version
  local docker_mcp_version
  docker_mcp_version=$(docker mcp version 2>/dev/null | head -1 || echo "unavailable")
  logs="=== DOCKER MCP ===\nversion: $docker_mcp_version\n\n"

  # MCP client and server status
  local mcp_clients
  mcp_clients=$(docker mcp client ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "unavailable")
  logs="${logs}=== MCP CLIENTS ===\n$mcp_clients\n\n"

  # Installed clients (system-level detection, independent of docker mcp)
  local ic_list=""
  for client in "${KNOWN_CLIENTS[@]}"; do
    if is_client_installed "$client"; then
      ic_list="${ic_list:+$ic_list, }$client"
    fi
  done
  logs="${logs}=== INSTALLED CLIENTS ===\n${ic_list:-none}\n\n"

  local mcp_servers
  mcp_servers=$(docker mcp server ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "unavailable")
  logs="${logs}=== MCP SERVERS ===\n$mcp_servers\n\n"

  # Config, volumes, containers
  if [[ -d "$HOME/.config/chalk-mcp" ]]; then
    local config_files
    config_files=$(find "$HOME/.config/chalk-mcp" -type f 2>/dev/null | sed "s|$HOME|~|g" || echo "none")
    logs="${logs}=== CONFIG FILES ===\n$config_files\n\n"
  fi

  local volumes
  volumes=$(docker volume ls -q --filter name=chalk-mcp 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "none")
  logs="${logs}=== VOLUMES ===\n$volumes\n\n"

  local containers
  containers=$(docker ps --filter "name=chalk-mcp" --format "{{.Names}}:{{.Status}}" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "none")
  logs="${logs}=== CONTAINERS ===\n$containers\n\n"

  # Chalk application log
  local chalk_log_path="$HOME/.config/chalk-mcp/chalk.log"
  if [[ -f "$chalk_log_path" ]]; then
    local chalk_log
    chalk_log=$(tail -50 "$chalk_log_path" 2>/dev/null || echo "")
    [[ -n "$chalk_log" ]] && logs="${logs}=== CHALK LOG ===\n$chalk_log\n\n"
  fi

  # MCP container log
  local mcp_logs
  mcp_logs=$(docker logs --tail 50 chalk-mcp-server 2>&1 || echo "")
  [[ -n "$mcp_logs" ]] && logs="${logs}=== MCP CONTAINER LOG ===\n$mcp_logs"

  # Build JSON matching bugreport.BugReport schema
  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  local report_id
  report_id=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "setup-$(date +%s)")

  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
print(json.dumps({
    'id': sys.argv[1],
    'timestamp': sys.argv[2],
    'error_message': sys.argv[3],
    'error_context': 'setup.sh --report-bug',
    'description': sys.argv[4],
    'chalk_version': sys.argv[5],
    'setup_mode': 'setup-script',
    'platform': sys.argv[6] + '/' + sys.argv[7],
    'system_info': {
        'docker_version': sys.argv[8],
        'docker_server': sys.argv[9],
        'container_runtime': sys.argv[10],
        'host_os': sys.argv[6],
        'host_arch': sys.argv[7],
        'mcp_server_version': 'setup-script',
        'in_container': False,
        'has_docker_access': sys.argv[11] == 'true',
        'has_network_access': sys.argv[12] == 'true',
    },
    'logs': sys.argv[13],
    'retry_count': 0,
}, indent=2))
" "$report_id" "$timestamp" "$error_message" "$description" \
      "$chalk_version" "$host_os" "$host_arch" \
      "$docker_version" "$docker_server" "$container_runtime" \
      "$has_docker" "$has_network" "$(printf '%b' "$logs")"
  elif command -v jq &>/dev/null; then
    jq -n \
      --arg id "$report_id" \
      --arg ts "$timestamp" \
      --arg err "$error_message" \
      --arg desc "$description" \
      --arg cv "$chalk_version" \
      --arg dv "$docker_version" \
      --arg ds "$docker_server" \
      --arg cr "$container_runtime" \
      --arg hos "$host_os" \
      --arg ha "$host_arch" \
      --argjson hd "$has_docker" \
      --argjson hn "$has_network" \
      --arg logs "$(printf '%b' "$logs")" \
      '{
        id: $id,
        timestamp: $ts,
        error_message: $err,
        error_context: "setup.sh --report-bug",
        description: $desc,
        chalk_version: $cv,
        setup_mode: "setup-script",
        platform: "\($hos)/\($ha)",
        system_info: {
          docker_version: $dv,
          docker_server: $ds,
          container_runtime: $cr,
          host_os: $hos,
          host_arch: $ha,
          mcp_server_version: "setup-script",
          in_container: false,
          has_docker_access: $hd,
          has_network_access: $hn
        },
        logs: $logs,
        retry_count: 0
      }'
  else
    err "python3 or jq required for bug reports"
    return 1
  fi
}

collect_diagnostics_text() {
  echo "=== Chalk MCP Server - Bug Report ==="
  echo ""
  echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "OS: $(uname -s) $(uname -r) ($(uname -m))"
  echo ""

  echo "--- Docker ---"
  docker version --format 'Client: {{.Client.Version}} / Server: {{.Server.Version}}' 2>/dev/null || echo "Docker: not available"
  echo "Docker MCP: $(docker mcp version 2>/dev/null || echo 'not available')"
  echo ""

  echo "--- MCP Clients ---"
  docker mcp client ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "docker mcp client ls failed"
  echo ""

  echo "--- Installed Clients (system detection) ---"
  for client in "${KNOWN_CLIENTS[@]}"; do
    if is_client_installed "$client"; then
      echo "  $client: installed"
    else
      echo "  $client: not found"
    fi
  done
  echo ""

  echo "--- MCP Servers ---"
  docker mcp server ls 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "docker mcp server ls failed"
  echo ""

  echo "--- Chalk MCP Config ---"
  if [[ -d "$HOME/.config/chalk-mcp" ]]; then
    echo "Config dir exists: yes"
    find "$HOME/.config/chalk-mcp" -type f 2>/dev/null | sed "s|$HOME|~|g" || true
  else
    echo "Config dir exists: no"
  fi
  echo ""

  echo "--- Docker Volumes ---"
  docker volume ls --filter name=chalk-mcp 2>/dev/null || true
  echo ""

  echo "--- Running Containers ---"
  docker ps --filter "name=chalk-mcp" --format "{{.Names}} {{.Image}} {{.Status}}" 2>/dev/null || true
  echo ""
}

run_bug_report() {
  BUG_REPORT_API="${CHALKAPI_URL:-https://chalk.try.crashoverride.run}/v1/bugreport"

  echo ""
  echo "┌────────────────────────────────────────────────────────────────┐"
  echo "│                   Chalk MCP Server - Bug Report                │"
  echo "└────────────────────────────────────────────────────────────────┘"
  echo ""

  info "Collecting diagnostics..."
  echo ""

  # Show human-readable diagnostics
  local text_report
  text_report=$(collect_diagnostics_text)
  echo "$text_report"
  echo ""

  # Prompt for error description
  local error_message=""
  local description=""
  if is_interactive; then
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    read -p "  What went wrong? (required): " -r error_message < /dev/tty
    if [[ -z "$error_message" ]]; then
      err "Error description is required"
      exit 1
    fi
    read -p "  Additional context (optional): " -r description < /dev/tty
    echo ""
  else
    error_message="setup.sh bug report (non-interactive)"
  fi

  # Build JSON payload matching bugreport.BugReport schema
  local json_payload
  if ! json_payload=$(collect_diagnostics_json "$error_message" "$description") || [[ -z "$json_payload" ]]; then
    err "Failed to build report payload"
    exit 1
  fi

  local report_id queue_file
  report_id=$(extract_report_id "$json_payload")
  if [[ -z "$report_id" ]]; then
    err "Failed to determine report ID"
    exit 1
  fi

  # Queue locally using the same on-disk format/path the server sender consumes.
  if ! queue_file=$(queue_bug_report "$json_payload"); then
    err "Failed to queue bug report"
    exit 1
  fi
  info "Report queued at: $queue_file"

  # Submit to Crash Override backend
  info "Submitting to Crash Override..."
  local http_code
  http_code=$(curl -s -o /tmp/chalk-mcp-bug-response.txt -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$json_payload" \
    --max-time 15 \
    "$BUG_REPORT_API" 2>/dev/null || echo "000")

  if [[ "$http_code" =~ ^2 ]]; then
    rm -f "$queue_file"
    ok "Bug report submitted successfully"
    info "Report ID: $report_id"
  else
    warn "Could not submit automatically (HTTP $http_code)"
    info "Queued report will be retried by chalk-mcp-server on its next send cycle"
    info "Queued file: $queue_file"
  fi
  echo ""
}

# Initialize colors on source
setup_colors
