# Nomad Dev Stack — Troubleshooting

> Every error we hit, and how to fix it.

---

## Table of Contents

1. [Port Already in Use (EADDRINUSE)](#port-already-in-use)
2. [Tailscale Not Connecting](#tailscale-not-connecting)
3. [Firewall Blocking Connections](#firewall-blocking)
4. [code-server 404 / Connection Refused](#code-server-not-responding)
5. [Mobile Browser Can't Reach Laptop](#mobile-cant-reach)
6. [Authentication Failures](#auth-failures)
7. [Git Push/Pull Issues Across Devices](#git-issues)
8. [WSL2 Networking Issues](#wsl2-issues)
9. [Performance Problems (Lag, Slow Sync)](#performance)
10. [Battery Drain on Mobile](#battery-drain)

---

## Port Already in Use

### Symptoms
```
error listen EADDRINUSE: address already in use 0.0.0.0:8080
```

### Cause
Another process is using the port code-server wants.

### Fix

**Option 1: Use a different port**
```bash
code-server --bind-addr 0.0.0.0:8081 --auth password
```

**Option 2: Kill the process on that port**
```bash
# Find what's using it
sudo lsof -i :8080

# Kill it
sudo kill -9 <PID>
```

**Option 3: Find which process and decide**
```bash
sudo ss -tlnp | grep 8080
```

### Prevention
The installer defaults to port 8081 (not 8080) to avoid this. If you change it, pick a high port:
```bash
# Good: unlikely to conflict
code-server --bind-addr 0.0.0.0:8443

# Bad: commonly used by other services
code-server --bind-addr 0.0.0.0:8080
code-server --bind-addr 0.0.0.0:3000
```

---

## Tailscale Not Connecting

### Symptoms
- `tailscale status` shows nothing
- Can't ping the other device
- `tailscale ping <hostname>` times out

### Cause 1: Not logged in
### Fix
```bash
sudo tailscale up
```
Authenticate in the browser window that opens.

### Cause 2: Different Tailscale accounts
### Fix
Both devices must use the **same account**.

Check on each device:
```bash
tailscale status
```

If the usernames don't match, re-authenticate one of them.

### Cause 3: Tailscale service not running
### Fix
```bash
# Check status
sudo systemctl status tailscaled

# Start it
sudo systemctl start tailscaled
sudo systemctl enable tailscaled
```

### Cause 4: Firewall blocking UDP
### Fix
Tailscale uses UDP 41641. Allow it:
```bash
sudo ufw allow 41641/udp
sudo ufw reload
```

---

## Firewall Blocking

### Symptoms
- code-server runs but you can't connect
- `curl http://localhost:8081` works from laptop, but phone can't reach it

### Cause
Local firewall (ufw, firewalld, iptables) is blocking the port.

### Fix

**UFW (Ubuntu/Debian):**
```bash
sudo ufw status
sudo ufw allow 8081/tcp
sudo ufw reload
```

**firewalld (Fedora/CentOS):**
```bash
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

**iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
```

### Prevention
The installer attempts to auto-configure the firewall, but some systems need manual intervention.

---

## code-server Not Responding

### Symptoms
- Browser shows "This site can't be reached"
- `ERR_CONNECTION_REFUSED`
- `404 Not Found`

### Cause 1: code-server isn't running
### Fix
```bash
# Check if running
ps aux | grep code-server

# Start it manually
nohup code-server --bind-addr 0.0.0.0:8081 --auth password > /dev/null 2>&1 &

# Or via systemd
sudo systemctl start nomad-dev-stack
sudo systemctl status nomad-dev-stack
```

### Cause 2: Wrong bind address
### Fix
Make sure you're binding to `0.0.0.0`, not `127.0.0.1` or `localhost`:
```bash
code-server --bind-addr 0.0.0.0:8081
```

`127.0.0.1` only allows connections from the same machine.

### Cause 3: code-server crashed
### Fix
Check logs:
```bash
# Systemd logs
sudo journalctl -u nomad-dev-stack -f

# Direct logs
cat ~/.local/share/code-server/logs/
```

---

## Mobile Can't Reach Laptop

### Symptoms
- Phone browser shows "This site can't be reached"
- Works on laptop but not phone

### Diagnosis Steps

**1. Is Tailscale connected on both?**
```bash
# On laptop
tailscale status
# On phone: check Tailscale app
```

**2. Can you ping the laptop from the phone?**
```bash
# On phone (Termux or a-Shell)
ping 100.x.x.x  # laptop's Tailscale IP
```

**3. Is code-server actually running?**
```bash
# On laptop
curl http://localhost:8081
```

**4. Is the port open?**
```bash
# On laptop
sudo ss -tlnp | grep 8081
```

### Fix by Scenario

| Scenario | Fix |
|----------|-----|
| Tailscale not connected | `sudo tailscale up` on both devices |
| Can't ping | Check Tailscale app for VPN toggle |
| code-server not running | Start it: `sudo systemctl start nomad-dev-stack` |
| Port not listening | Check firewall; ensure binding to `0.0.0.0` |
| Works on WiFi but not 5G | Tailscale should work on 5G — check mobile data settings |

---

## Authentication Failures

### Symptoms
- Password doesn't work
- "Unauthorized" error
- Can't log in

### Cause 1: Wrong password
### Fix
```bash
# Check saved password
cat ~/.nomad-dev-stack/code-server-password.txt
```

Or reset it:
```bash
# Edit config
nano ~/.config/code-server/config.yaml

# Change password line, then restart
sudo systemctl restart nomad-dev-stack
```

### Cause 2: Auth set to "none" accidentally
### Fix
Edit `~/.config/code-server/config.yaml`:
```yaml
auth: password
password: your-new-password
```

Restart:
```bash
sudo systemctl restart nomad-dev-stack
```

### Prevention
Never use `auth: none` unless you're on a trusted local network with no exposure. The installer defaults to `password` for a reason.

---

## Git Issues Across Devices

### Symptoms
- Changes made on phone don't appear on laptop
- "Your branch is ahead/behind by X commits"
- Merge conflicts when switching devices

### Fix

**The Golden Rule: Push before you switch.**

Set up a pre-switch habit:
```bash
git add .
git commit -m "wip: current state"
git push
```

**Auto-push on save (VS Code setting):**
```json
{
  "git.enableSmartCommit": true,
  "git.confirmSync": false,
  "git.autofetch": true
}
```

**Git hooks for safety:**
```bash
# Create a pre-commit hook
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
echo "Remember to push when you switch devices!"
EOF
chmod +x .git/hooks/pre-commit
```

---

## WSL2 Issues

### Symptoms
- code-server runs in WSL but Windows browser can't reach it
- `localhost:8081` works in WSL but not from Windows
- Tailscale shows WSL as a separate device

### Cause 1: Binding to localhost instead of 0.0.0.0
### Fix
WSL has its own network stack. Bind to `0.0.0.0` so Windows can reach it:
```bash
code-server --bind-addr 0.0.0.0:8081
```

Then access from Windows browser using the WSL IP:
```bash
# In WSL
hostname -I
# Use the first IP shown, e.g., http://172.22.123.45:8081
```

### Cause 2: Windows Firewall blocking WSL ports
### Fix
```powershell
# In PowerShell (as Administrator)
New-NetFirewallRule -DisplayName "WSL-code-server" -Direction Inbound -LocalPort 8081 -Protocol TCP -Action Allow
```

### Cause 3: WSL using different IP after restart
### Fix
WSL IPs change on restart. Use Tailscale (stable `100.x.x.x`) or set a static IP in `.wslconfig`:

```ini
# In Windows: %UserProfile%\.wslconfig
[wsl2]
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
```

Then `localhost:8081` from Windows will just work.

### Cause 4: Systemd not enabled in WSL
### Fix
```bash
# Check
sudo systemctl status

# If it fails, enable systemd:
sudo nano /etc/wsl.conf
# Add:
# [boot]
# systemd=true

# Then in PowerShell:
wsl --shutdown
# Restart WSL
```

---

## Performance

### Symptoms
- Slow typing response
- Lag when switching files
- Long load times

### Cause 1: Network latency
### Fix
```bash
# Check Tailscale latency
tailscale ping <hostname>

# If >100ms, try a closer Tailscale DERP relay:
sudo tailscale up --accept-routes --advertise-exit-node=false
```

### Cause 2: code-server underpowered
### Fix
If your laptop is old/slow:
```bash
# Limit VS Code extensions
# Disable unnecessary extensions in the sidebar

# Reduce editor features
# ~/.local/share/code-server/User/settings.json
{
  "editor.minimap.enabled": false,
  "editor.hover.enabled": false,
  "editor.parameterHints.enabled": false
}
```

### Cause 3: Browser on phone is slow
### Fix
- Use a lightweight browser (Chrome, Firefox — avoid Samsung Internet)
- Close other tabs
- Disable browser extensions

---

## Battery Drain

### Symptoms
- Phone battery dies faster when using Nomad
- Tailscale app shows high battery usage

### Cause
Tailscale keeps a persistent VPN connection.

### Fix

**Option 1: Use local-only mode when at home**
When both devices are on the same WiFi, you don't need Tailscale:
```bash
# Use local IP instead
http://192.168.1.42:8081
```

**Option 2: Disconnect Tailscale when not coding**
Toggle the VPN off in the Tailscale app when you're done.

**Option 3: Enable Tailscale's battery optimization**
On Android: Tailscale app → Settings → Battery → Allow background activity (disable)

---

## Still Stuck?

1. Run the health checker: `bash scripts/status-check.sh`
2. Check logs: `cat ~/.nomad-dev-stack/install.log`
3. Join [Discord](https://discord.gg/nomadstack) and ask
4. Open a GitHub issue with the output of `status-check.sh`

**Remember: every problem in this doc was solved by someone before you.**
