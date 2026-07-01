#!/usr/bin/env bash
set -Eeuo pipefail

SSH_PORT="${SSH_PORT:-22}"
ALLOW_3XUI_PORT="${ALLOW_3XUI_PORT:-2053}"
ALLOW_HY2_PORT="${ALLOW_HY2_PORT:-443}"
ALLOW_AWG_PORT="${ALLOW_AWG_PORT:-59567}"
ENABLE_BBR="${ENABLE_BBR:-yes}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

echo "==> Updating system"
apt update
DEBIAN_FRONTEND=noninteractive apt -y upgrade

echo "==> Installing packages"
apt install -y \
  curl wget git nano vim htop ncdu unzip zip tar \
  ca-certificates gnupg lsb-release \
  nftables fail2ban cron logrotate \
  traceroute mtr-tiny dnsutils net-tools iproute2 \
  jq qrencode

echo "==> Enabling nftables"
systemctl enable --now nftables

echo "==> Writing nftables firewall"

cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        iif "lo" accept

        ct state established,related accept
        ct state invalid drop

        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept

        tcp dport ${SSH_PORT} accept

        # 3x-ui / panel / optional web panel
        tcp dport ${ALLOW_3XUI_PORT} accept

        # Hysteria2
        udp dport ${ALLOW_HY2_PORT} accept

        # AmneziaWG / WireGuard
        udp dport ${ALLOW_AWG_PORT} accept

        # Optional: HTTP/HTTPS for certbot, x-ui, fallback sites
        tcp dport { 80, 443 } accept

        counter drop
    }

    chain forward {
        type filter hook forward priority 0;
        policy accept;
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
EOF

nft -f /etc/nftables.conf
systemctl restart nftables

echo "==> Configuring Fail2Ban"

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd
banaction = nftables-multiport

[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = %(sshd_log)s
maxretry = 4
bantime = 6h
EOF

systemctl enable --now fail2ban
systemctl restart fail2ban

echo "==> Applying sysctl tuning"

cat > /etc/sysctl.d/99-vps-bootstrap.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl --system >/dev/null

echo "==> Creating vps-status command"

cat > /usr/local/bin/vps-status <<'EOF'
#!/usr/bin/env bash

echo "===== SYSTEM ====="
hostnamectl
echo

echo "===== IP ====="
curl -4 -s ifconfig.me || true
echo
curl -6 -s ifconfig.me || true
echo

echo "===== SERVICES ====="
systemctl --no-pager --type=service --state=running | grep -E 'ssh|fail2ban|nft|x-ui|hysteria|wg|amnezia' || true
echo

echo "===== FIREWALL ====="
nft list ruleset
echo

echo "===== FAIL2BAN ====="
fail2ban-client status sshd || true
echo

echo "===== PORTS ====="
ss -tulpen
EOF

chmod +x /usr/local/bin/vps-status

echo "==> Done"
echo
echo "VPS bootstrap completed."
echo "SSH port: ${SSH_PORT}/tcp"
echo "3x-ui port: ${ALLOW_3XUI_PORT}/tcp"
echo "Hysteria2 port: ${ALLOW_HY2_PORT}/udp"
echo "AmneziaWG/WireGuard port: ${ALLOW_AWG_PORT}/udp"
echo
echo "Check status:"
echo "  vps-status"
