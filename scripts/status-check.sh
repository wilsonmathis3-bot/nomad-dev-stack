#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  NOMAD DEV STACK — Health Check
#  Run from laptop or phone to verify everything is working.
# ═══════════════════════════════════════════════════════════════

CONFIG_DIR="${HOME}/.nomad-dev-stack"
CONFIG_FILE="${CONFIG_DIR}/remote-config.json"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}   $*"; }

# ── Load config ───────────────────────────────────────────────
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        if command -v jq &>/dev/null; then
            REMOTE_URL="$(jq -r '.url // empty' "$CONFIG_FILE")"
            REMOTE_IP="$(jq -r '.ip // empty' "$CONFIG_FILE")"
        else
            REMOTE_URL="$(grep '"url"' "$CONFIG_FILE" | sed 's/.*"url".*"\(.*\)".*/\1/')"
            REMOTE_IP="$(grep '"ip"' "$CONFIG_FILE" | sed 's/.*"ip".*"\(.*\)".*/\1/')"
        fi
    fi
    
    # Fallback: try to detect Tailscale IP
    if [[ -z "${REMOTE_IP:-}" ]] && command -v tailscale &>/dev/null; then
        REMOTE_IP="$(tailscale ip -4 2>/dev/null | head -1 || echo "")"
    fi
    
    # Fallback: local IP
    if [[ -z "${REMOTE_IP:-}" ]]; then
        REMOTE_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")"
    fi
    
    # Default URL
    REMOTE_URL="${REMOTE_URL:-http://${REMOTE_IP}:8081}"
}

# ── Check 1: Network connectivity ─────────────────────────────
check_network() {
    info "Checking network connectivity..."
    
    if ping -c 1 -W 2 "$REMOTE_IP" &>/dev/null; then
        ok "Host ${REMOTE_IP} is reachable"
        return 0
    else
        fail "Host ${REMOTE_IP} is NOT reachable"
        warn "  → Check if Tailscale is connected on both devices"
        warn "  → Try: tailscale status"
        return 1
    fi
}

# ── Check 2: code-server response ─────────────────────────────
check_code_server() {
    info "Checking code-server..."
    
    local http_code
    http_code="$(curl -s -o /dev/null -w "%{http_code}" "${REMOTE_URL}/health" 2>/dev/null || echo "000")"
    
    if [[ "$http_code" == "200" ]]; then
        ok "code-server is responding (HTTP 200)"
        return 0
    elif [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
        ok "code-server is responding (auth required — expected)"
        return 0
    elif [[ "$http_code" == "000" ]]; then
        fail "code-server is NOT responding"
        warn "  → Check if code-server is running: ps aux | grep code-server"
        warn "  → Check if firewall is blocking port"
        warn "  → Try: sudo systemctl start nomad-dev-stack"
        return 1
    else
        warn "code-server returned HTTP $http_code"
        return 1
    fi
}

# ── Check 3: Tailscale status ─────────────────────────────────
check_tailscale() {
    if ! command -v tailscale &>/dev/null; then
        warn "Tailscale not installed on this device"
        return 0
    fi
    
    info "Checking Tailscale..."
    
    local ts_status
    ts_status="$(tailscale status 2>/dev/null || echo "")"
    
    if [[ -n "$ts_status" ]]; then
        ok "Tailscale is running"
        echo ""
        echo "$ts_status"
        return 0
    else
        fail "Tailscale is not running or not authenticated"
        warn "  → Run: sudo tailscale up"
        return 1
    fi
}

# ── Check 4: Git workspace ────────────────────────────────────
check_git() {
    local workspace="${NOMAD_WORKSPACE_DIR:-${HOME}/workspace}"
    
    if [[ ! -d "$workspace/.git" ]]; then
        warn "No Git repo found in ${workspace}"
        return 0
    fi
    
    info "Checking Git workspace..."
    cd "$workspace"
    
    local branch
    branch="$(git branch --show-current 2>/dev/null || echo "unknown")"
    local status
    status="$(git status --short 2>/dev/null || echo "")"
    
    ok "Git repo on branch: ${branch}"
    
    if [[ -n "$status" ]]; then
        warn "Uncommitted changes:"
        echo "$status"
    else
        ok "Working tree clean"
    fi
}

# ── Check 5: Disk space ───────────────────────────────────────
check_disk() {
    info "Checking disk space..."
    
    local usage
    usage="$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')"
    
    if [[ "$usage" -lt 80 ]]; then
        ok "Disk usage: ${usage}%"
    elif [[ "$usage" -lt 90 ]]; then
        warn "Disk usage: ${usage}% — getting full"
    else
        fail "Disk usage: ${usage}% — CRITICAL"
    fi
}

# ── Main ──────────────────────────────────────────────────────
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           NOMAD DEV STACK — Health Check                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    load_config
    
    local failures=0
    
    check_network || ((failures++))
    check_code_server || ((failures++))
    check_tailscale || true  # Optional
    check_git || true        # Optional
    check_disk || true       # Optional
    
    echo ""
    if [[ "$failures" -eq 0 ]]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              ✅ ALL CHECKS PASSED                            ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              ⚠️  ${failures} CHECK(S) FAILED                         ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}See above for specific fixes.${NC}"
    fi
}

main "$@"
