# 🚀 VPS Bootstrap Toolkit

A lightweight toolkit for preparing a fresh **Debian 13 VPS** before installing VPN services.

Designed for:

- AmneziaWG
- WireGuard
- Hysteria 2
- 3x-ui
- Xray
- sing-box

The toolkit performs the initial server configuration and provides convenient management commands for further administration.

---

# Features

✔ System update

✔ Common administration utilities

✔ nftables firewall

✔ Fail2Ban

✔ TCP BBR

✔ IPv4 / IPv6 forwarding

✔ System tuning (sysctl)

✔ Firewall management

✔ VPS health monitoring

✔ Toolkit self-update

---

# Installation

## Using wget (recommended)

```bash
wget -qO- https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh | bash
```

## Using curl

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh)
```

---

# Custom Installation

Default ports:

| Service | Port |
|---------|------|
| SSH | 22/TCP |
| HTTP | 80/TCP |
| HTTPS | 443/TCP |
| 3x-ui | 2053/TCP |
| Hysteria2 | 443/UDP |
| AmneziaWG | 59567/UDP |

Example:

```bash
SSH_PORT=2222 \
ALLOW_3XUI_PORT=8443 \
ALLOW_HY2_PORT=8443 \
ALLOW_AWG_PORT=51820 \
wget -qO- https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh | bash
```

---

# Commands

The recommended way to use the toolkit is through the `vps` command.

Show all available commands:

```bash
vps
```

---

## System

Show server status

```bash
vps status
```

Run health check

```bash
vps check
```

Update Debian

```bash
vps update
```

Show Toolkit version

```bash
vps version
```

Update Toolkit

```bash
vps self-update
```

---

## Firewall

Open TCP port

```bash
vps open-port 8443 tcp x-ui
```

Open UDP port

```bash
vps open-port 51820 udp wireguard
```

Close port

```bash
vps close-port 8443 tcp
```

Reload firewall

```bash
vps reload-fw
```

---

# Configuration

Toolkit configuration is stored in:

```text
/etc/vps-bootstrap/
```

Configuration files:

```text
config.conf
ports.conf
```

Example `ports.conf`:

```ini
TCP_PORTS="
22:ssh
80:http
443:https
2053:3x-ui
"

UDP_PORTS="
443:hysteria2
59567:amneziawg
"
```

---

# Project Structure

```
vps-bootstrap
│
├── install.sh
│
├── configs
│   ├── config.conf
│   └── ports.conf
│
├── scripts
│   ├── vps
│   ├── vps-status
│   ├── vps-check
│   ├── vps-update
│   ├── vps-version
│   ├── vps-self-update
│   ├── vps-open-port
│   ├── vps-close-port
│   └── vps-reload-fw
│
└── README.md
```

---

# Toolkit Commands

| Command | Description |
|----------|-------------|
| `vps` | Show help |
| `vps status` | Server status |
| `vps check` | Health check |
| `vps update` | Update Debian packages |
| `vps version` | Toolkit version |
| `vps self-update` | Update Toolkit |
| `vps open-port` | Open TCP/UDP port |
| `vps close-port` | Close TCP/UDP port |
| `vps reload-fw` | Reload nftables |

---

# Roadmap

System

- [ ] Backup
- [ ] Restore
- [ ] Scheduled updates

Firewall

- [ ] Port aliases
- [ ] Port groups
- [ ] Import / Export

VPN

- [ ] AmneziaWG installer
- [ ] Hysteria2 installer
- [ ] 3x-ui installer
- [ ] Client management

Monitoring

- [ ] VPS information
- [ ] Network tests
- [ ] Speed test
- [ ] DNS diagnostics

---

# Requirements

- Debian 13 (Trixie)
- Root access
- Internet connection

---

# License

MIT
