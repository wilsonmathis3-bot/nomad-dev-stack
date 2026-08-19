#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  NOMAD DEV STACK — Android Mobile Setup
#  Run this inside Termux on your Android device.
# ═══════════════════════════════════════════════════════════════

CONFIG_DIR="${HOME}/.nomad-dev-stack"
LOG_FILE="${CONFIG_DIR}/mobile-setup.log"

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

# ── Detect Termux ─────────────────────────────────────────────
if [[ -z "${TERMUX_VERSION:-}" ]]; then
    error "This script must run inside Termux."
    error "Install Termux from F-Droid (NOT the Play Store version)."
    error "URL: https://f-droid.org/packages/com.termux/"
    exit 1
fi

ok "Termux detected: $TERMUX_VERSION"

# ── Update packages ───────────────────────────────────────────
info "Updating Termux packages..."
pkg update -y

# ── Install essentials ────────────────────────────────────────
info "Installing essential packages..."
pkg install -y git openssh curl wget jq nano vim

# ── Configure Git ─────────────────────────────────────────────
info "Git configuration..."
if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
    echo -en "${CYAN}Your Git name: ${NC}"
    read -r git_name
    git config --global user.name "$git_name"
fi

if [[ -z "$(git config --global user.email 2>/dev/null)" ]]; then
    echo -en "${CYAN}Your Git email: ${NC}"
    read -r git_email
    git config --global user.email "$git_email"
fi

ok "Git configured"

# ── Create connection helpers ─────────────────────────────────
info "Creating connection helpers..."

mkdir -p "$CONFIG_DIR"

# Read saved config from laptop
if [[ -f "${CONFIG_DIR}/remote-config.json" ]]; then
    REMOTE_URL="$(jq -r '.url' "${CONFIG_DIR}/remote-config.json")"
    REMOTE_PASS="$(jq -r '.password' "${CONFIG_DIR}/remote-config.json")"
else
    warn "No remote config found. You'll need to enter details manually."
    echo -en "${CYAN}Laptop Tailscale IP (e.g., 100.x.x.x): ${NC}"
    read -r remote_ip
    echo -en "${CYAN}Port (default 8081): ${NC}"
    read -r remote_port
    remote_port="${remote_port:-8081}"
    REMOTE_URL="http://${remote_ip}:${remote_port}"
    REMOTE_PASS=""
fi

# Create alias script
cat > "${CONFIG_DIR}/connect.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
# Quick connect to your Nomad Dev Stack

URL="${REMOTE_URL}"
PASS="${REMOTE_PASS}"

echo "Opening Nomad Dev Stack..."
echo "URL: \$URL"

if [[ -n "\$PASS" ]]; then
    echo "Password: \$PASS"
fi

# Try to open in browser
termux-open-url "\$URL" 2>/dev/null || \
    echo "Open this URL in your browser: \$URL"
EOF

chmod +x "${CONFIG_DIR}/connect.sh"

# Add alias to bashrc
if ! grep -q "nomad-connect" "${HOME}/.bashrc" 2>/dev/null; then
    echo "" >> "${HOME}/.bashrc"
    echo "# Nomad Dev Stack aliases" >> "${HOME}/.bashrc"
    echo "alias nomad-connect='bash ${CONFIG_DIR}/connect.sh'" >> "${HOME}/.bashrc"
    echo "alias nomad-status='curl -s ${REMOTE_URL}/health || echo \"Nomad server unreachable\"'" >> "${HOME}/.bashrc"
fi

ok "Connection helpers created"

# ── SSH key setup (optional) ──────────────────────────────────
info "SSH key setup..."
if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
    echo -en "${CYAN}Generate SSH key for passwordless access? [y/N]: ${NC}"
    read -r gen_ssh
    if [[ "$gen_ssh" =~ ^[Yy]$ ]]; then
        ssh-keygen -t rsa -b 4096 -f "${HOME}/.ssh/id_rsa" -N ""
        ok "SSH key generated. Add this to your laptop's ~/.ssh/authorized_keys:"
        cat "${HOME}/.ssh/id_rsa.pub"
    fi
else
    ok "SSH key already exists"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 ANDROID SETUP COMPLETE!                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Quick commands:${NC}"
echo -e "  ${GREEN}nomad-connect${NC}     — Open your dev environment in browser"
echo -e "  ${GREEN}nomad-status${NC}      — Check if server is reachable"
echo -e ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Install Tailscale from Play Store / F-Droid"
echo -e "  2. Log in with the SAME account as your laptop"
echo -e "  3. Run: ${GREEN}source ~/.bashrc${NC}"
echo -e "  4. Run: ${GREEN}nomad-connect${NC}"
echo ""
