# Nomad Dev Stack — Security Guide

> How to stay safe while coding from anywhere.

---

## Threat Model

Nomad Dev Stack is designed for **personal use** — one developer, multiple devices. It is NOT designed for:
- Public-facing production servers
- Multi-user team environments without additional hardening
- Storing sensitive secrets (API keys, passwords) without additional layers

## Default Security Posture

The installer applies these defaults:

| Setting | Default | Why |
|---------|---------|-----|
| Authentication | Password | Prevents unauthorized access |
| Bind address | `0.0.0.0` | Allows mobile access (required) |
| Tailscale | Enabled | Encrypted transport between devices |
| Auto-start | Yes | Service runs as unprivileged user |
| HTTPS | Disabled | Tailscale provides transport encryption |

## Why Password Auth?

We default to password authentication because:

1. **OAuth requires external identity providers** — adds complexity for personal use
2. **No auth is dangerous** — `0.0.0.0` without auth exposes your editor to the world
3. **Passwords are simple to rotate** — see below

## How to Rotate Your Password

```bash
# Generate new password
NEW_PASS=$(openssl rand -base64 24)

# Update config
sed -i "s/^password:.*/password: ${NEW_PASS}/" ~/.config/code-server/config.yaml

# Save to secure location
echo "$NEW_PASS" > ~/.nomad-dev-stack/code-server-password.txt
chmod 600 ~/.nomad-dev-stack/code-server-password.txt

# Restart service
sudo systemctl restart nomad-dev-stack

# Show new password
echo "New password: $NEW_PASS"
```

## Tailscale ACLs (Access Control)

For extra security, restrict which devices can talk to each other:

```json
// In Tailscale admin console: https://login.tailscale.com/admin/acls
{
  "acls": [
    {
      "action": "accept",
      "src": ["mikes-s25-ultra"],
      "dst": ["lenovo:8081"]
    }
  ]
}
```

This ensures your phone can only reach port 8081 on your laptop, nothing else.

## HTTPS via Reverse Proxy

If you have a domain name, set up HTTPS:

```bash
# Install nginx and certbot
sudo apt install nginx certbot python3-certbot-nginx

# Copy the nginx template
cp configs/nginx-reverse-proxy.conf.tmpl /etc/nginx/sites-available/nomad

# Edit with your domain
sudo nano /etc/nginx/sites-available/nomad

# Enable site
sudo ln -s /etc/nginx/sites-available/nomad /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Get certificate
sudo certbot --nginx -d nomad.yourdomain.com
```

Now access via: `https://nomad.yourdomain.com`

## What NOT to Do

| Don't | Why |
|-------|-----|
| Expose `0.0.0.0:8081` without auth | Anyone on the internet can access your code |
| Use `auth: none` on public WiFi | Coffee shop attackers can read your files |
| Commit passwords to Git | They'll be in your repo history forever |
| Run code-server as root | Compromised editor = compromised system |
| Share your Tailscale account | They can access all your devices |
| Use weak passwords | `password123` is not a password |

## SSH Key Authentication (Advanced)

For terminal access without passwords:

```bash
# On phone (Termux or a-Shell)
ssh-keygen -t ed25519 -f ~/.ssh/nomad_key

# Copy public key to laptop
ssh-copy-id -i ~/.ssh/nomad_key.pub user@laptop-tailscale-ip

# Connect
ssh -i ~/.ssh/nomad_key user@laptop-tailscale-ip
```

## Audit Logging

Monitor access to your dev environment:

```bash
# View code-server access logs
sudo journalctl -u nomad-dev-stack -f

# View Tailscale audit logs
tailscale status --json | jq '.Peer[] | {Hostname, TailscaleIPs, LastSeen}'
```

## Incident Response

If you suspect unauthorized access:

1. **Immediate:**
   ```bash
   sudo systemctl stop nomad-dev-stack
   sudo tailscale down
   ```

2. **Rotate credentials:**
   ```bash
   # New password
   NEW_PASS=$(openssl rand -base64 32)
   # Update config and restart
   ```

3. **Check logs:**
   ```bash
   sudo journalctl -u nomad-dev-stack --since "1 hour ago"
   ```

4. **Verify Tailscale devices:**
   ```bash
   tailscale status
   # Look for unknown devices
   ```

5. **Report:**
   Open a GitHub issue if you believe there's a vulnerability in the project itself.

## Security Checklist

Before you consider your setup "done":

- [ ] Password is random and >20 characters
- [ ] Tailscale is authenticated on both devices
- [ ] code-server runs as non-root user
- [ ] Firewall allows only necessary ports
- [ ] Logs are monitored periodically
- [ ] Git repository does not contain secrets
- [ ] You know how to emergency-shutdown the service

**Paranoia is a feature, not a bug.** 🔒
