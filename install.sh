#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://raw.githubusercontent.com/MyNicknme/vps-bootstrap/main"

SSH_PORT="${SSH_PORT:-22}"
ALLOW_3XUI_PORT="${ALLOW_3XUI_PORT:-2053}"
ALLOW_HY2_PORT="${ALLOW_HY2_PORT:-443}"
ALLOW_AWG_PORT="${ALLOW_AWG_PORT:-59567}"

download_file() {
  local url="$1"
  local out="$2"

  for i in 1 2 3 4 5; do
    echo "Downloading: $url"

    if curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$out"; then
      return 0
    fi

    echo "Download failed. Retry $i/5..."
    sleep $((i * 5))
  done

  echo "ERROR: failed to download after retries:"
  echo "$url"
  exit 1
}

install_tool() {
  local name="$1"
  local url="${REPO_URL}/scripts/${name}"

  echo "Installing ${name}..."
  download_file "$url" "/usr/local/bin/${name}"
  chmod +x "/usr/local/bin/${name}"
  echo "Installed ${name}"
}

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

download_file "${REPO_URL}/configs/ports.conf" /etc/vps-bootstrap/ports.conf
download_file "${REPO_URL}/configs/config.conf" /etc/vps-bootstrap/config.conf

install_tool vps
install_tool vps-status
install_tool vps-update
install_tool vps-check
install_tool vps-reload-fw
install_tool vps-open-port
install_tool vps-close-port
install_tool vps-version
install_tool vps-self-update
install_tool vps-reality

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
echo "  vps status"
echo "  vps check"
echo "  vps version"
echo
