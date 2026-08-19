#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  NOMAD DEV STACK — iOS Mobile Setup
#  Run this inside a-Shell or ShellFish on your iOS device.
# ═══════════════════════════════════════════════════════════════

CONFIG_DIR="${HOME}/.nomad-dev-stack"

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

# ── Detect environment ────────────────────────────────────────
if command -v python3 &>/dev/null && [[ -d "/var/mobile" ]]; then
    ok "iOS environment detected (a-Shell / ShellFish)"
else
    warn "This script is designed for iOS (a-Shell or ShellFish)"
    warn "If you're using a different terminal app, some features may not work."
fi

# ── Read connection details ───────────────────────────────────
info "Setting up connection to your Nomad Dev Stack..."

if [[ -f "${CONFIG_DIR}/remote-config.json" ]]; then
    REMOTE_URL="$(python3 -c "import json; print(json.load(open('${CONFIG_DIR}/remote-config.json'))['url'])" 2>/dev/null || echo "")"
    REMOTE_PASS="$(python3 -c "import json; print(json.load(open('${CONFIG_DIR}/remote-config.json'))['password'])" 2>/dev/null || echo "")"
else
    warn "No remote config found."
    echo -en "${CYAN}Laptop Tailscale IP (e.g., 100.x.x.x): ${NC}"
    read -r remote_ip
    echo -en "${CYAN}Port (default 8081): ${NC}"
    read -r remote_port
    remote_port="${remote_port:-8081}"
    REMOTE_URL="http://${remote_ip}:${remote_port}"
    REMOTE_PASS=""
fi

# ── Create connection helper ──────────────────────────────────
mkdir -p "$CONFIG_DIR"

cat > "${CONFIG_DIR}/connect-ios.sh" <<EOF
#!/bin/bash
# Open Nomad Dev Stack on iOS

URL="${REMOTE_URL}"

echo "Opening: \$URL"

# Try to open in Safari
open "\$URL" 2>/dev/null || \
    echo "Copy this URL to Safari: \$URL"
EOF

chmod +x "${CONFIG_DIR}/connect-ios.sh"

# ── SSH key setup ─────────────────────────────────────────────
info "SSH key setup..."
if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
    echo -en "${CYAN}Generate SSH key? [y/N]: ${NC}"
    read -r gen_ssh
    if [[ "$gen_ssh" =~ ^[Yy]$ ]]; then
        ssh-keygen -t rsa -b 4096 -f "${HOME}/.ssh/id_rsa" -N ""
        ok "SSH key generated. Add this to your laptop's ~/.ssh/authorized_keys:"
        cat "${HOME}/.ssh/id_rsa.pub"
    fi
else
    ok "SSH key already exists"
fi

# ── Shortcuts app automation ──────────────────────────────────
info "Shortcuts automation..."
cat > "${CONFIG_DIR}/shortcuts-url.txt" <<EOF
Nomad Dev Stack URL:
${REMOTE_URL}

To create a one-tap shortcut:
1. Open Shortcuts app
2. Create new shortcut
3. Add "Open URLs" action
4. Paste: ${REMOTE_URL}
5. Add to Home Screen
EOF

ok "Shortcuts URL saved to: ${CONFIG_DIR}/shortcuts-url.txt"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 iOS SETUP COMPLETE!                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Your Nomad URL:${NC}  ${REMOTE_URL}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Install Tailscale from App Store"
echo -e "  2. Log in with the SAME account as your laptop"
echo -e "  3. Create a Shortcuts automation (see shortcuts-url.txt)"
echo -e "  4. Open ${REMOTE_URL} in Safari"
echo ""
