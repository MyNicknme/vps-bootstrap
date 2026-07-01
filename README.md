# 🚀 VPS Bootstrap Toolkit

A lightweight toolkit for preparing a fresh **Debian 13 VPS** before installing VPN services such as:

- AmneziaWG
- WireGuard
- Hysteria 2
- 3x-ui
- Xray / sing-box

The goal is to provide a consistent, secure and repeatable server configuration with a single command.

---

# Features

The bootstrap script performs the following tasks:

- Updates the operating system
- Installs common administration utilities
- Installs and configures **Fail2Ban**
- Configures **nftables firewall**
- Enables **TCP BBR**
- Enables IPv4/IPv6 forwarding
- Applies recommended sysctl parameters
- Installs VPS Toolkit commands

---

# Installed Packages

- curl
- wget
- git
- nano
- vim
- htop
- ncdu
- unzip
- zip
- nftables
- fail2ban
- jq
- qrencode
- traceroute
- dnsutils
- net-tools
- iproute2

---

# Installation

Using **wget** (recommended):

```bash
wget -qO- https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh | bash
```

or using curl:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh)
```

---

# Custom Ports

Default ports:

| Service | Port |
|---------|------|
| SSH | 22/TCP |
| 3x-ui | 2053/TCP |
| Hysteria 2 | 443/UDP |
| AmneziaWG | 59567/UDP |

Custom values can be supplied during installation:

```bash
SSH_PORT=2222 \
ALLOW_3XUI_PORT=2053 \
ALLOW_HY2_PORT=8443 \
ALLOW_AWG_PORT=51820 \
wget -qO- https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main/install.sh | bash
```

---

# VPS Toolkit Commands

## Server Status

```bash
vps-status
```

Shows:

- System information
- Public IP
- Memory usage
- Disk usage
- Running services
- Firewall status
- Fail2Ban status
- Open TCP/UDP ports
- BBR status
- IP Forward status

---

## Health Check

```bash
vps-check
```

Performs a security audit of the server:

- Firewall
- Fail2Ban
- SSH configuration
- TCP BBR
- IP Forward
- Swap
- Disk usage
- Pending reboot

Returns an overall health score and warnings if issues are detected.

---

## System Update

```bash
vps-update
```

Runs:

- apt update
- apt upgrade
- apt autoremove
- apt autoclean

and reports whether a reboot is required.

---

# Project Structure

```
vps-bootstrap
│
├── install.sh
│
├── scripts
│   ├── vps-status
│   ├── vps-check
│   └── vps-update
│
├── configs
│
└── README.md
```

---

# Roadmap

Upcoming features:

- vps-open-port
- vps-close-port
- vps-backup
- vps-restore

VPN installers:

- AmneziaWG
- Hysteria 2
- 3x-ui

Automatic backup and restore.

---

# Requirements

- Debian 13 (Trixie)
- Root access
- Internet connection

---

# License

MIT
