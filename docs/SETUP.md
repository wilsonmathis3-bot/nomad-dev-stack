# Nomad Dev Stack — Setup Guide

> Complete walkthrough from zero to coding on two devices.

---

## Prerequisites

Before you start, you'll need:

| Item | Why |
|------|-----|
| A laptop with Linux or macOS | The "server" — does the actual computing |
| A smartphone or tablet | The "client" — your window into the server |
| A GitHub account | For Git sync and optional Codespaces fallback |
| 15 minutes | That's literally it |

### Supported Operating Systems

**Primary (Laptop):**
- Ubuntu 20.04+ (LTS recommended)
- Debian 11+
- Fedora 35+
- Arch Linux (rolling)
- macOS 12+ (Monterey)
- Windows 10/11 with WSL2 (Ubuntu recommended)

**Mobile:**
- Android 10+ (with Termux from F-Droid)
- iOS 15+ (with a-Shell or ShellFish)
- iPadOS 15+
- ChromeOS (with Linux container enabled)

---

## Step 1: Run the Installer on Your Laptop

```bash
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
./install.sh
```

The installer will ask you 5 questions:

1. **Editor** — Which code editor? (VS Code / Cursor / Windsurf / Neovim)
2. **Mobile OS** — What's your phone running? (Android / iOS / iPadOS / ChromeOS)
3. **Network** — How to connect devices? (Tailscale / Cloudflare / ngrok / Local)
4. **Port** — What port for the editor server? (default: 8081)
5. **Auto-start** — Start on boot? (yes / no)

### What the installer does

- Installs `code-server` (VS Code in browser)
- Installs Tailscale (encrypted mesh VPN)
- Configures authentication
- Creates a systemd service (if auto-start = yes)
- Generates a QR code for mobile connection

### After installation

You'll see output like:

```
🎉 SETUP COMPLETE!

📱  Mobile access (anywhere):  http://100.93.23.90:8081
   Password: xK9#mP2$vL7@nQ4

💻  Local access (same WiFi):  http://192.168.1.42:8081
   Password: xK9#mP2$vL7@nQ4

⚠️  IMPORTANT:
   • Save your password: ~/.nomad-dev-stack/code-server-password.txt
   • Install Tailscale on your phone
   • Log in with the SAME account on both devices
```

**Screenshot or save this output.** You'll need the password and IP.

---

## Step 2: Install Tailscale on Both Devices

Tailscale creates an encrypted tunnel between your devices. It's free for personal use.

### On Laptop

Already done by the installer. Verify:

```bash
tailscale status
```

You should see your laptop listed with a `100.x.x.x` IP.

### On Android

1. Open Google Play Store or F-Droid
2. Search "Tailscale"
3. Install and open
4. Log in with the **same account** you used on your laptop
5. You should see your laptop in the device list

### On iOS / iPadOS

1. Open App Store
2. Search "Tailscale"
3. Install and open
4. Log in with the **same account**
5. Toggle the VPN switch on

---

## Step 3: Run Mobile Setup

### Android (Termux)

First, install Termux **from F-Droid** (not Play Store — the Play Store version is outdated and broken):

```bash
# In Termux
pkg install git
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
bash scripts/setup-mobile-android.sh
```

This installs Git, SSH, and creates helper aliases.

### iOS (a-Shell)

```bash
# In a-Shell
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
bash scripts/setup-mobile-ios.sh
```

This sets up connection helpers and creates a Shortcuts automation.

---

## Step 4: Verify Connection

### From your phone

**Android:**
```bash
nomad-connect
```

**iOS:**
```bash
bash ~/.nomad-dev-stack/connect-ios.sh
```

Or open Safari and navigate to:
```
http://100.x.x.x:8081
```
(Replace `100.x.x.x` with your laptop's Tailscale IP from Step 1)

You should see a login screen. Enter the password from Step 1.

### Test editing

1. Create a file on your laptop in VS Code
2. Open the same file on your phone
3. Edit from either device — changes are live

---

## Step 5: Configure Your Editor

### VS Code Settings

The installer creates optimized settings at:
```
~/.local/share/code-server/User/settings.json
```

Key settings:
- Auto-save every second
- Minimap disabled (saves screen space on mobile)
- GitLens and Prettier recommended

### Recommended Extensions

Install these in code-server for the best experience:

| Extension | Why |
|-----------|-----|
| GitLens | Supercharged Git in the sidebar |
| Prettier | Auto-format on save |
| ESLint | Catch errors before you commit |
| Material Icon Theme | Pretty file icons |
| One Dark Pro | Easy-on-the-eyes theme |
| Code Spell Checker | Because typos in comments are embarrassing |

---

## Per-OS Notes

### Ubuntu / Debian

If `apt` hangs, try:
```bash
sudo dpkg --configure -a
sudo apt-get update
```

### Fedora

`dnf` is slower than `apt` but more reliable. If packages fail:
```bash
sudo dnf clean all
sudo dnf makecache
```

### Arch

You probably don't need this guide. But if `pacman` breaks:
```bash
sudo pacman -Syu
```

### macOS

If `brew` isn't installed, the installer will prompt you. Install from [brew.sh](https://brew.sh).

**Permission issues?**
```bash
sudo chown -R $(whoami) /usr/local
```

### Windows (WSL2)

Install WSL2 first:
```powershell
# In PowerShell (as Administrator)
wsl --install
```

**WSL2 networking quirks:**
- code-server binds to `0.0.0.0` inside WSL, accessible from Windows browser at the WSL IP
- Find your WSL IP: `hostname -I` inside WSL
- Tailscale works inside WSL — install it there, not on Windows host

**Systemd in WSL:**
Some WSL distros don't have systemd enabled. Check:
```bash
# In WSL
sudo systemctl status
```

If it fails, enable systemd in `/etc/wsl.conf`:
```ini
[boot]
systemd=true
```

Then restart WSL:
```powershell
wsl --shutdown
```

**File access between Windows and WSL:**
- Access Windows files from WSL: `/mnt/c/Users/YourName/...`
- Access WSL files from Windows: `\\wsl$\Ubuntu\home\yourname\...`

---

## Per-Mobile-OS Notes

### Android Termux Tips

- **Use a Bluetooth keyboard** — coding on a touchscreen is painful
- **Enable extra keys** — `termux.properties`: `extra-keys = [['ESC','TAB','CTRL','ALT','-','DOWN','UP']]`
- **Storage access** — `termux-setup-storage` to access `/sdcard`
- **Background execution** — Disable battery optimization for Termux in Android settings

### iOS Shortcuts Automation

After running the iOS setup script:

1. Open **Shortcuts** app
2. Create new shortcut → Add Action → **Open URLs**
3. Paste your Nomad URL
4. Tap **Share** → **Add to Home Screen**
5. Name it "Nomad Dev"

Now you have a one-tap icon to your dev environment.

### ChromeOS

Enable Linux container:
1. Settings → Developers → Linux development environment
2. Install Nomad Dev Stack inside the Linux container
3. Access via Chrome browser → `http://100.x.x.x:8081`

---

## Troubleshooting Quick Reference

| Symptom | Quick Fix |
|---------|-----------|
| Can't reach laptop from phone | Check `tailscale status` on both |
| Port already in use | Change port in `~/.config/code-server/config.yaml` |
| Forgot password | Check `~/.nomad-dev-stack/code-server-password.txt` |
| code-server won't start | `sudo systemctl restart nomad-dev-stack` |
| Mobile browser shows 404 | Verify code-server is running: `curl http://localhost:8081` |
| Slow response | Check Tailscale connection quality: `tailscale ping <hostname>` |

**Full troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Next Steps

- [ ] Set up Git auto-push (cron job or VS Code extension)
- [ ] Install your preferred theme and extensions
- [ ] Configure `nomad-status` to run every morning
- [ ] Read the [Security Guide](SECURITY.md)
- [ ] Join the [Discord community](https://discord.gg/nomadstack)

**Welcome to the Nomad life. Code anywhere.** 🖤
