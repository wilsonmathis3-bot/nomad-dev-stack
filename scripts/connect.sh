#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  NOMAD DEV STACK — Universal Connection Helper
#  Detects device type and connects to your dev environment.
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

# ── Detect platform ───────────────────────────────────────────
detect_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        echo "android"
    elif [[ -d "/var/mobile" ]] || [[ "$OSTYPE" == "darwin"* && "$(uname -m)" == "arm64" ]]; then
        echo "ios"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# ── Load config ───────────────────────────────────────────────
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No config found at $CONFIG_FILE"
        warn "Run the setup script for your device first."
        exit 1
    fi
    
    # Try to parse with jq, fallback to grep/sed
    if command -v jq &>/dev/null; then
        REMOTE_URL="$(jq -r '.url // empty' "$CONFIG_FILE")"
        REMOTE_PASS="$(jq -r '.password // empty' "$CONFIG_FILE")"
    else
        REMOTE_URL="$(grep '"url"' "$CONFIG_FILE" | sed 's/.*"url".*"\(.*\)".*/\1/')"
        REMOTE_PASS="$(grep '"password"' "$CONFIG_FILE" | sed 's/.*"password".*"\(.*\)".*/\1/')"
    fi
    
    if [[ -z "$REMOTE_URL" ]]; then
        error "Invalid config file. Missing 'url' field."
        exit 1
    fi
}

# ── Copy to clipboard ─────────────────────────────────────────
copy_to_clipboard() {
    local text="$1"
    local platform
    platform="$(detect_platform)"
    
    case "$platform" in
        android)
            echo "$text" | termux-clipboard-set 2>/dev/null || \
                echo "$text" > /sdcard/nomad-url.txt
            ;;
        ios|macos)
            echo "$text" | pbcopy 2>/dev/null || \
                echo "$text"
            ;;
        linux)
            echo "$text" | xclip -selection clipboard 2>/dev/null || \
                echo "$text" | xsel --clipboard 2>/dev/null || \
                echo "$text"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

# ── Open URL ──────────────────────────────────────────────────
open_url() {
    local url="$1"
    local platform
    platform="$(detect_platform)"
    
    case "$platform" in
        android)
            termux-open-url "$url" 2>/dev/null || \
                echo "Open this URL: $url"
            ;;
        ios|macos)
            open "$url" 2>/dev/null || \
                echo "Open this URL: $url"
            ;;
        linux)
            xdg-open "$url" 2>/dev/null || \
                echo "Open this URL: $url"
            ;;
        *)
            echo "Open this URL: $url"
            ;;
    esac
}

# ── Main ──────────────────────────────────────────────────────
main() {
    local copy_flag=false
    
    # Parse args
    for arg in "$@"; do
        case "$arg" in
            --copy|-c)
                copy_flag=true
                ;;
            --help|-h)
                echo "Usage: $0 [--copy]"
                echo "  --copy    Copy URL to clipboard instead of opening"
                exit 0
                ;;
        esac
    done
    
    load_config
    
    local platform
    platform="$(detect_platform)"
    
    echo -e "${CYAN}Nomad Dev Stack${NC}"
    echo -e "${CYAN}Platform:${NC}  $platform"
    echo -e "${CYAN}URL:${NC}      $REMOTE_URL"
    
    if [[ -n "$REMOTE_PASS" ]]; then
        echo -e "${CYAN}Password:${NC} $REMOTE_PASS"
    fi
    
    echo ""
    
    if [[ "$copy_flag" == true ]]; then
        copy_to_clipboard "$REMOTE_URL"
        ok "URL copied to clipboard"
    else
        info "Opening browser..."
        open_url "$REMOTE_URL"
    fi
}

main "$@"
