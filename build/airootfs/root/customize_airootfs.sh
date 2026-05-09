#!/bin/bash
# VenomOS airootfs customization script
# Runs inside the chroot during archiso build
set -e

echo "[*] VenomOS: Customizing airootfs..."

# ── Users ─────────────────────────────────────────────────────────────────────
useradd -m -G wheel,audio,video,optical,storage,network,docker -s /bin/zsh venom 2>/dev/null || true
echo "venom:live" | chpasswd
echo "root:venom" | chpasswd

# Passwordless sudo for venom
echo "venom ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/venom
chmod 440 /etc/sudoers.d/venom

# ── Shell ─────────────────────────────────────────────────────────────────────
chsh -s /bin/zsh venom
chsh -s /bin/zsh root

# Copy skel to venom home
cp -r /etc/skel/. /home/venom/ 2>/dev/null || true
cp -r /etc/skel/. /root/ 2>/dev/null || true
chown -R venom:venom /home/venom

# ── Hostname ──────────────────────────────────────────────────────────────────
echo "venomOS" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   venomOS
::1         localhost
EOF

# ── Services ──────────────────────────────────────────────────────────────────
systemctl enable NetworkManager
systemctl enable tor
systemctl enable dnscrypt-proxy
systemctl enable docker
systemctl disable systemd-resolved 2>/dev/null || true

# ── DNS — route through dnscrypt-proxy ───────────────────────────────────────
cat > /etc/resolv.conf << 'EOF'
nameserver 127.0.0.1
options edns0 single-request-reopen
EOF
chattr +i /etc/resolv.conf 2>/dev/null || true

# ── Stealth — MAC randomization ───────────────────────────────────────────────
chmod +x /etc/NetworkManager/dispatcher.d/99-macspoof 2>/dev/null || true

# ── Tor configuration ─────────────────────────────────────────────────────────
cat >> /etc/tor/torrc << 'EOF'

# VenomOS Tor config
SocksPort 9050
SocksPort 9150
DNSPort 5353
TransPort 9040
AutomapHostsOnResolve 1
EOF

# ── Proxychains — Tor by default ──────────────────────────────────────────────
cat > /etc/proxychains.conf << 'EOF'
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 127.0.0.1 9050
EOF

# ── Hardening ─────────────────────────────────────────────────────────────────
cat > /etc/sysctl.d/99-venomos.conf << 'EOF'
net.ipv4.ip_forward = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.disable_ipv6 = 1
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1
kernel.kptr_restrict = 2
net.ipv4.conf.all.rp_filter = 1
EOF

# ── MOTD ─────────────────────────────────────────────────────────────────────
cat > /etc/motd << 'EOF'

 __   _____ _  _  ___  __  __  ___  ___
 \ \ / / __| \| |/ _ \|  \/  |/ _ \/ __|
  \ V /| _|| .` | (_) | |\/| | (_) \__ \
   \_/ |___|_|\_|\___/|_|  |_|\___/|___/

  VenomOS 1.0 — Intelligence. Precision. Persistence.
  Run 'venom-help' to see available tools.
  Run 'sudo venom-setup' to install personal tools.

EOF

# ── VenomOS bin permissions ───────────────────────────────────────────────────
mkdir -p /opt/venomOS/{bin,tools,vms,isos}
chmod +x /opt/venomOS/bin/* 2>/dev/null || true
for cmd in venom-setup venom-help venom-vm venom-install; do
    [ -f "/opt/venomOS/bin/$cmd" ] && \
        ln -sf "/opt/venomOS/bin/$cmd" "/usr/local/bin/$cmd"
done

# ── Fastfetch VenomOS config ──────────────────────────────────────────────────
mkdir -p /etc/fastfetch
cat > /etc/fastfetch/config.jsonc << 'FFEOF'
{
  "logo": {
    "type": "builtin",
    "source": "arch",
    "color": { "1": "green", "2": "green" }
  },
  "display": {
    "separator": "  ",
    "color": { "keys": "green", "values": "white" }
  },
  "modules": [
    "break",
    { "type": "custom", "format": "  [0;32mVenomOS 1.0[0m — Intelligence. Precision. Persistence." },
    "separator",
    { "type": "os",       "key": "  OS      " },
    { "type": "kernel",   "key": "  Kernel  " },
    { "type": "uptime",   "key": "  Uptime  " },
    { "type": "shell",    "key": "  Shell   " },
    { "type": "cpu",      "key": "  CPU     " },
    { "type": "memory",   "key": "  Memory  " },
    "break",
    { "type": "colors", "symbol": "block", "paddingLeft": 2 },
    "break"
  ]
}
FFEOF

echo "[+] VenomOS airootfs customization complete."
