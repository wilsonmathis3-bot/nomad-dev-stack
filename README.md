# Nomad Dev Stack

Turn your laptop into a remote dev server (code-server + Tailscale) and use it from any device, with an optional VS Code extension ("Nomad Jarvis") for in-editor AI chat.

Full documentation lives in [`docs/`](docs/README.md):

- [Setup guide](docs/SETUP.md)
- [Security notes](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Quick start (from a clone)

```bash
git clone https://github.com/wilsonmathis3-bot/nomad-dev-stack.git
cd nomad-dev-stack
bash install.sh            # laptop / server
bash scripts/status-check.sh
```

Phone setup: `scripts/setup-mobile-android.sh` (Termux) or `scripts/setup-mobile-ios.sh`.

## Repository layout

| Path | What it is |
|------|------------|
| `install.sh` | Interactive installer for the laptop/server side |
| `scripts/` | Connect, mobile setup and health-check scripts |
| `configs/` | Templates for code-server, systemd, nginx, Tailscale, Cloudflare Tunnel |
| `vscode-extension/` | Nomad Jarvis VS Code extension (TypeScript) |

## Building the VS Code extension

```bash
cd vscode-extension
npm install
npm run compile     # outputs to vscode-extension/out/
```

Requires VS Code 1.82+ (the extension uses the built-in `fetch` from VS Code's Node 18 runtime).

CI (`.github/workflows/ci.yml`) runs ShellCheck on the scripts and compiles the extension on every push and pull request.
