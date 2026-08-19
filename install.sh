#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  NOMAD DEV STACK — Interactive Installer
#  One command to sync your laptop and phone for seamless coding.
# ═══════════════════════════════════════════════════════════════

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOME}/.nomad-dev-stack/install.log"
CONFIG_DIR="${HOME}/.nomad-dev-stack"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Logging ───────────────────────────────────────────────────
log() {
    local level="$1"; shift
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "[${timestamp}] [${level}] ${msg}" >> "$LOG_FILE"
}

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; log "INFO" "$@"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; log "WARN" "$@"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; log "ERROR" "$@"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; log "OK" "$@"; }

# ── Prerequisites ─────────────────────────────────────────────
check_prereqs() {
    info "Checking prerequisites..."
    
    # Ensure config dir exists
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
    
    # Check for required tools
    local missing=()
    for cmd in curl wget git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing[*]}"
        error "Install them and re-run."
        exit 1
    fi
    
    ok "Prerequisites met"
}

# ── OS Detection ──────────────────────────────────────────────
detect_os() {
    if [[ -n "${NOMAD_OS:-}" ]]; then
        echo "$NOMAD_OS"
        return
    fi
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            local id
            id="$(. /etc/os-release && echo "$ID")"
            case "$id" in
                ubuntu|debian) echo "ubuntu" ;;
                fedora|rhel|centos) echo "fedora" ;;
                arch|manjaro) echo "arch" ;;
                *) echo "ubuntu" ;; # default fallback
            esac
        else
            echo "ubuntu"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        echo "windows"
    else
        echo "ubuntu"
    fi
}

# ── Interactive Prompts ───────────────────────────────────────
prompt() {
    local var="$1"
    local question="$2"
    local default="${3:-}"
    local options="${4:-}"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $question${NC}"
    if [[ -n "$options" ]]; then
        echo -e "${CYAN}  Options: $options${NC}"
    fi
    if [[ -n "$default" ]]; then
        echo -e "${CYAN}  [default: $default]${NC}"
    fi
    echo -en "${CYAN}  → ${NC}"
    
    local answer
    if [[ -n "${!var:-}" ]]; then
        answer="${!var}"
        echo "$answer"
    else
        read -r answer
        [[ -z "$answer" && -n "$default" ]] && answer="$default"
    fi
    
    eval "export $var=\"$answer\""
}

# ── Package Manager ───────────────────────────────────────────
install_packages() {
    local os="$1"
    shift
    local packages=("$@")
    
    info "Installing packages for $os: ${packages[*]}"
    
    case "$os" in
        ubuntu|debian)
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
            ;;
        fedora|rhel|centos)
            sudo dnf install -y "${packages[@]}" 2>/dev/null || \
                sudo yum install -y "${packages[@]}" 2>/dev/null || true
            ;;
        arch)
            sudo pacman -Sy --noconfirm "${packages[@]}" 2>/dev/null || true
            ;;
        macos)
            if command -v brew &>/dev/null; then
                brew install "${packages[@]}" 2>/dev/null || true
            else
                warn "Homebrew not found. Install from https://brew.sh"
            fi
            ;;
        windows)
            info "Installing packages via WSL apt..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
            ;;
    esac
}

# ── Install code-server ───────────────────────────────────────
install_code_server() {
    local os="$1"
    
    if command -v code-server &>/dev/null; then
        ok "code-server already installed: $(code-server --version | head -1)"
        return
    fi
    
    info "Installing code-server..."
    
    case "$os" in
        ubuntu|debian|fedora|rhel|centos|arch|windows)
            curl -fsSL https://code-server.dev/install.sh | sh
            ;;
        macos)
            brew install code-server
            ;;
    esac
    
    ok "code-server installed"
}

# ── Install Tailscale ─────────────────────────────────────────
install_tailscale() {
    local os="$1"
    
    if command -v tailscale &>/dev/null; then
        ok "Tailscale already installed: $(tailscale version | head -1)"
        return
    fi
    
    info "Installing Tailscale..."
    
    case "$os" in
        ubuntu|debian|windows)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        fedora|rhel|centos)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        arch)
            sudo pacman -Sy --noconfirm tailscale
            ;;
        macos)
            brew install tailscale
            ;;
    esac
    
    ok "Tailscale installed"
}

# ── Configure code-server ─────────────────────────────────────
configure_code_server() {
    local port="${1:-8081}"
    local auth="${2:-password}"
    local bind_addr="0.0.0.0"
    
    local config_dir="${HOME}/.config/code-server"
    local config_file="${config_dir}/config.yaml"
    
    mkdir -p "$config_dir"
    
    # Generate random password if needed
    local password
    if [[ "$auth" == "password" ]]; then
        password="$(openssl rand -base64 24 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24)"
    else
        password=""
    fi
    
    cat > "$config_file" <<EOF
# Nomad Dev Stack — code-server configuration
# Generated: $(date)
bind-addr: ${bind_addr}:${port}
auth: ${auth}
EOF
    
    if [[ -n "$password" ]]; then
        echo "password: ${password}" >> "$config_file"
    fi
    
    echo "user-data-dir: ${HOME}/.local/share/code-server" >> "$config_file"
    
    # Save password to config dir for reference
    if [[ -n "$password" ]]; then
        echo "$password" > "${CONFIG_DIR}/code-server-password.txt"
        chmod 600 "${CONFIG_DIR}/code-server-password.txt"
    fi
    
    ok "code-server configured on port $port"
    
    # Return password for display
    echo "$password"
}

# ── Create systemd service ────────────────────────────────────
create_systemd_service() {
    local port="${1:-8081}"
    local user
    user="$(whoami)"
    
    local service_file="/etc/systemd/system/nomad-dev-stack.service"
    
    info "Creating systemd service..."
    
    sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Nomad Dev Stack — code-server
After=network.target

[Service]
Type=simple
User=${user}
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:${port} --auth password
Restart=on-failure
RestartSec=5
Environment=HOME=${HOME}

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable nomad-dev-stack.service
    
    ok "Systemd service created and enabled"
}

# ── Start services ────────────────────────────────────────────
start_services() {
    local method="${1:-tailscale}"
    
    info "Starting services..."
    
    # Start Tailscale
    if [[ "$method" == "tailscale" ]]; then
        if command -v tailscale &>/dev/null; then
            info "Starting Tailscale (you may need to authenticate)..."
            sudo tailscale up --hostname "nomad-$(hostname | cut -c1-20)" || true
            ok "Tailscale started"
        fi
    fi
    
    # Start code-server
    if command -v systemctl &>/dev/null; then
        sudo systemctl start nomad-dev-stack.service || {
            warn "Failed to start via systemd. Starting manually..."
            nohup code-server --bind-addr 0.0.0.0:"${NOMAD_PORT:-8081}" > /dev/null 2>&1 &
        }
    else
        nohup code-server --bind-addr 0.0.0.0:"${NOMAD_PORT:-8081}" > /dev/null 2>&1 &
    fi
    
    ok "code-server started"
    sleep 2
}

# ── Get Tailscale IP ──────────────────────────────────────────
get_tailscale_ip() {
    if command -v tailscale &>/dev/null; then
        tailscale ip -4 2>/dev/null | head -1 || echo ""
    else
        echo ""
    fi
}

# ── Get local IP ──────────────────────────────────────────────
get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || \
        ip addr show | grep "inet " | head -1 | awk '{print $2}' | cut -d/ -f1 || \
        ifconfig | grep "inet " | head -1 | awk '{print $2}' || \
        echo "127.0.0.1"
}

# ── Generate QR code URL ──────────────────────────────────────
generate_qr_url() {
    local url="$1"
    # Use qrenco.de API to generate QR code image
    echo "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$(printf '%s' "$url" | jq -sRr '@uri')"
}

# ── Main ──────────────────────────────────────────────────────
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           🌐  NOMAD DEV STACK v${VERSION}                         ║"
    echo "║                                                              ║"
    echo "║     Your code. Any device. Zero context switching.           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prereqs
    
    local os
    os="$(detect_os)"
    info "Detected OS: $os"
    
    # ── Interactive prompts ────────────────────────────────────
    prompt "NOMAD_EDITOR" "Which editor do you want to use?" "vscode" "vscode | cursor | windsurf | neovim"
    prompt "NOMAD_MOBILE" "What's your mobile device OS?" "android" "android | ios | ipados | chromeos"
    prompt "NOMAD_NETWORK" "How do you want to connect devices?" "tailscale" "tailscale | cloudflare_tunnel | ngrok | zerotier | local_only"
    prompt "NOMAD_PORT" "What port should code-server use?" "8081"
    prompt "NOMAD_AUTOSTART" "Start on boot?" "yes" "yes | no"
    
    # ── Install phase ──────────────────────────────────────────
    echo ""
    info "Installing dependencies..."
    
    install_packages "$os" curl wget git jq openssl
    
    if [[ "$NOMAD_EDITOR" == "vscode" || "$NOMAD_EDITOR" == "cursor" || "$NOMAD_EDITOR" == "windsurf" ]]; then
        install_code_server "$os"
    fi
    
    if [[ "$NOMAD_NETWORK" == "tailscale" ]]; then
        install_tailscale "$os"
    fi
    
    # ── Configure phase ────────────────────────────────────────
    echo ""
    info "Configuring services..."
    
    local password
    password="$(configure_code_server "$NOMAD_PORT" "password")"
    
    if [[ "$NOMAD_AUTOSTART" == "yes" ]]; then
        create_systemd_service "$NOMAD_PORT"
    fi
    
    # ── Start phase ────────────────────────────────────────────
    echo ""
    info "Starting services..."
    start_services "$NOMAD_NETWORK"
    
    # ── Display connection info ────────────────────────────────
    local tailscale_ip
    tailscale_ip="$(get_tailscale_ip)"
    local local_ip
    local_ip="$(get_local_ip)"
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   🎉 SETUP COMPLETE!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -n "$tailscale_ip" ]]; then
        local ts_url="http://${tailscale_ip}:${NOMAD_PORT}"
        echo -e "${CYAN}📱  Mobile access (anywhere):${NC}  $ts_url"
        echo -e "${CYAN}   Password:${NC} ${password}"
        echo ""
        echo -e "${CYAN}   QR Code:${NC} $(generate_qr_url "$ts_url")"
    fi
    
    local local_url="http://${local_ip}:${NOMAD_PORT}"
    echo -e "${CYAN}💻  Local access (same WiFi):${NC}  $local_url"
    echo -e "${CYAN}   Password:${NC} ${password}"
    echo ""
    
    echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
    echo -e "   • Save your password: ${CONFIG_DIR}/code-server-password.txt"
    echo -e "   • Install Tailscale on your phone from the app store"
    echo -e "   • Log in with the SAME account on both devices"
    echo -e "   • Run: ${GREEN}bash scripts/setup-mobile-${NOMAD_MOBILE}.sh${NC} on your phone"
    echo ""
    
    echo -e "${GREEN}   Happy coding, nomad. 🖤${NC}"
    echo ""
    
    log "COMPLETE" "Setup finished. Editor=$NOMAD_EDITOR Mobile=$NOMAD_MOBILE Network=$NOMAD_NETWORK Port=$NOMAD_PORT"
}

# ── Run ───────────────────────────────────────────────────────
main "$@"
