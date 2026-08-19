# Nomad Dev Stack

> **Your code. Any device. Zero context switching.**

Stop copy-pasting between your laptop and phone. Stop losing work when your battery dies. Run one command and turn any two devices into a seamless development environment.

---

## The Problem

You have a laptop. You have a phone. You code on both. But:

- Your laptop dies → your work dies with it
- You copy code to your phone, edit, copy back — a dozen times a day
- Context switching costs you 20+ minutes each time you pick up a different device
- Setting up remote dev environments is a weekend project you never finish

## The Solution

One installer. One command. Your laptop becomes the server, your phone becomes the terminal. Same files. Same editor. Same extensions. Anywhere you have signal.

```bash
curl -fsSL https://get.nomadstack.dev | bash
```

---

## What's Included

- ✅ **VS Code Extension** — "Nomad Jarvis" panel with context-aware chat, right-click actions
- ✅ **Interactive installer** — detects your OS, asks 5 questions, does the rest
- ✅ **code-server** — VS Code in your browser, works on any device
- ✅ **Tailscale mesh VPN** — encrypted, zero-config networking between devices
- ✅ **Auto-start service** — survives reboots, starts with your system
- ✅ **Mobile setup scripts** — one command to configure your phone
- ✅ **Health checker** — verify everything works from either device
- ✅ **Security hardening** — non-root service, firewall rules, auth defaults

## Supported Combinations

| Primary OS | Editor | Mobile OS | Network |
|-----------|--------|-----------|---------|
| Ubuntu | VS Code | Android | Tailscale ✅ |
| Debian | Cursor | iOS | Cloudflare Tunnel ✅ |
| Fedora | Windsurf | iPadOS | ngrok ✅ |
| Arch | Neovim | ChromeOS | ZeroTier ✅ |
| Arch | Neovim | ChromeOS | ZeroTier ✅ |
| macOS | — | — | Local Only ✅ |
| Windows (WSL) | VS Code | Android | Tailscale ✅ |

**If your combo isn't listed, it probably works anyway.** These are just the ones we've tested.

---

## Quick Start (3 Commands)

### 1. On your laptop

```bash
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
./install.sh
```

The installer will ask you 5 questions and do everything else.

### 2. On your phone

**Android (Termux):**
```bash
pkg install git
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
bash scripts/setup-mobile-android.sh
```

**iOS (a-Shell / ShellFish):**
```bash
git clone https://github.com/yourusername/nomad-dev-stack.git
cd nomad-dev-stack
bash scripts/setup-mobile-ios.sh
```

### 3. Connect

```bash
nomad-connect
```

Your browser opens. You're coding.

---

## Screenshots

| Laptop Setup | Mobile Access | Health Check |
|-------------|---------------|--------------|
| `[SCREENSHOT: VS Code in Simple Browser panel]` | `[SCREENSHOT: code-server on Android Chrome]` | `[SCREENSHOT: status-check output]` |

---

## Pricing

| Tier | Price | Includes |
|------|-------|----------|
| **Basic** | $29 | PDF guide + installer scripts |
| **Pro** | $79 | Above + video walkthrough + priority support |
| **Team** | $149 | Multi-seat license + CI/CD templates + custom branding |

**30-day money-back guarantee.** If it doesn't save you an hour in the first week, refund it.

---

## FAQ

**Q: Do I need to know Linux?**
A: No. The installer handles everything. If you can open a terminal, you can use this.

**Q: Does my phone need to be powerful?**
A: No. Your laptop does the heavy lifting. Your phone is just a window into it.

**Q: What if my laptop is off?**
A: Your code lives in Git. Push before you close the lid. Pull when you open it. The installer sets up Git auto-fetch.

**Q: Is this secure?**
A: Yes. Tailscale uses WireGuard (same encryption as VPNs). code-server requires authentication. We default to password auth and never expose unauthenticated services.

**Q: Can I use this with my team?**
A: The Team tier includes multi-seat licensing. Everyone gets the same environment.

**Q: What if I use Windows?**
A: Windows WSL2 is fully supported. Run the installer inside your WSL2 Ubuntu instance. Your Windows browser can access code-server at the WSL IP, and your phone connects via Tailscale. Native Windows (PowerShell) support is planned for a future release.

**Q: Will this drain my phone battery?**
A: No more than browsing a website. All compute happens on your laptop.

**Q: Can I use a tablet instead of a phone?**
A: Yes. iPadOS and Android tablets work identically.

**Q: What if Tailscale goes down?**
A: The installer also supports Cloudflare Tunnel, ngrok, and local-only mode as fallbacks.

**Q: Do you offer refunds?**
A: 30-day no-questions-asked refund policy.

---

## Testimonials

> *"I used to lose 30 minutes every time my laptop died. Now I just grab my phone and keep coding."*
> — **Early Beta User**

> *"Set it up in 10 minutes. Used it for a week. Bought the Pro tier immediately."*
> — **Indie Developer**

---

## Support

- 📖 [Full Setup Guide](docs/SETUP.md)
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md)
- 🔒 [Security Guide](docs/SECURITY.md)
- 💬 [Discord Community](https://discord.gg/nomadstack)

---

## License

MIT License — use it, modify it, sell your own fork. Just don't blame us if you rm -rf your home directory.

---

**Built by developers who were tired of context switching.**

🌐 [nomadstack.dev](https://nomadstack.dev) · 🐦 [@nomadstack](https://twitter.com/nomadstack) · 💻 [GitHub](https://github.com/yourusername/nomad-dev-stack)
