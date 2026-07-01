#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main"

SSH_PORT="${SSH_PORT:-22}"
ALLOW_3XUI_PORT="${ALLOW_3XUI_PORT:-2053}"
ALLOW_HY2_PORT="${ALLOW_HY2_PORT:-443}"
ALLOW_AWG_PORT="${ALLOW_AWG_PORT:-59567}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

echo "==> VPS Bootstrap started"

apt update
DEBIAN_FRONTEND=noninteractive apt -y upgrade

apt install -y \
  curl wget git nano vim htop ncdu unzip zip tar \
  ca-certificates gnupg lsb-release \
  nftables fail2ban cron logrotate \
  traceroute mtr-tiny dnsutils net-tools iproute2 \
  jq qrencode

echo "==> Configuring nftables"

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
        tcp dport ${ALLOW_3XUI_PORT} accept
        udp dport ${ALLOW_HY2_PORT} accept
        udp dport ${ALLOW_AWG_PORT} accept
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
systemctl enable --now nftables
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

echo "==> Installing VPS Toolkit"

mkdir -p /etc/vps-bootstrap

curl -fsSL --connect-timeout 10 --max-time 30 \
  "${REPO_URL}/configs/ports.conf" \
  -o /etc/vps-bootstrap/ports.conf
  
curl -fsSL --connect-timeout 10 --max-time 30 \
  "${REPO_URL}/configs/config.conf" \
  -o /etc/vps-bootstrap/config.conf

install_tool() {
  local name="$1"
  local url="${REPO_URL}/scripts/${name}"

  echo "Downloading ${name}..."

  if curl -fsSL --connect-timeout 10 --max-time 30 "$url" -o "/usr/local/bin/${name}"; then
    chmod +x "/usr/local/bin/${name}"
    echo "Installed ${name}"
  else
    echo "ERROR: failed to download ${name}"
    echo "Check URL: $url"
    exit 1
  fi
}

install_tool vps
install_tool vps-status
install_tool vps-update
install_tool vps-check
install_tool vps-reload-fw
install_tool vps-open-port
install_tool vps-close-port
install_tool vps-version
install_tool vps-self-update

vps-reload-fw

echo
echo "========================================="
echo " VPS Bootstrap completed"
echo "========================================="
echo "SSH port            : ${SSH_PORT}/tcp"
echo "3x-ui port          : ${ALLOW_3XUI_PORT}/tcp"
echo "Hysteria2 port      : ${ALLOW_HY2_PORT}/udp"
echo "AmneziaWG/WG port   : ${ALLOW_AWG_PORT}/udp"
echo
echo "Check status:"
echo "  vps-status"
echo "  vps-check"
echo
